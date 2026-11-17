# SEGUL CLI installer for Windows.
#
#   irm https://segul.app/install.ps1 | iex
#
# Downloads the pre-built `segul.exe` for this system from the latest GitHub
# release, installs it to ~\.local\bin, and adds that folder to the user PATH.
# It needs no administrator access and works in Windows PowerShell 5.1 and
# PowerShell 7.
#
# Options:
#
#   -Dir <path>        Install into <path> instead of ~\.local\bin.
#   -Version <tag>     Install a specific release, such as v0.23.2.
#   -NoModifyPath      Do not add the install folder to the user PATH.
#   -Uninstall         Remove the binary installed by this script.
#   -Help              Show this help.
#
# To pass options when piping, run the script as a script block:
#
#   & ([scriptblock]::Create((irm https://segul.app/install.ps1))) -Dir C:\Tools
#
# The same options can be set through SEGUL_INSTALL_DIR=<path> and
# SEGUL_VERSION=<tag>.

# Everything runs from Install-Segul, called on the last line, so a download
# cut short cannot execute half a script. Errors are thrown inside it, never
# `exit`, because `exit` would close the terminal when the script runs through
# iex. A failure sets $LASTEXITCODE to 1, and exits with 1 only when the
# installer runs from a script file.

param(
  [string]$Dir,
  [string]$Version,
  [switch]$NoModifyPath,
  [switch]$Uninstall,
  [switch]$Help
)

function Install-Segul {
  param(
    [string]$Dir,
    [string]$Version,
    [switch]$NoModifyPath,
    [switch]$Uninstall,
    [switch]$Help
  )

  # Preference variables are function-scoped, so the caller's session is not
  # changed when this runs through iex.
  Set-StrictMode -Version Latest
  $ErrorActionPreference = 'Stop'
  # The progress bar slows downloads in Windows PowerShell 5.1 many times over.
  $ProgressPreference = 'SilentlyContinue'

  # Helper functions read these through PowerShell's dynamic scoping.
  $Repo = 'hhandika/segul'
  $Binary = 'segul.exe'
  $DocsUrl = 'https://segul.app/docs/installation/intro/'

  if ($Help) {
    Show-Usage
    return $true
  }

  if (-not $Dir) { $Dir = $env:SEGUL_INSTALL_DIR }
  if (-not $Dir) { $Dir = Join-Path $HOME '.local\bin' }
  if (-not $Version) { $Version = $env:SEGUL_VERSION }
  if (-not $Version) { $Version = 'latest' }
  # Release tags start with v, so accept 0.23.2 for v0.23.2.
  if ($Version -match '^\d') { $Version = "v$Version" }

  # Resolve ~ and relative paths against the current PowerShell location.
  $Dir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Dir)

  try {
    if ($Uninstall) {
      Remove-Segul $Dir
      return $true
    }

    $asset = Select-Asset
    if ($Version -eq 'latest') {
      $url = "https://github.com/$Repo/releases/latest/download/$asset"
    } else {
      $url = "https://github.com/$Repo/releases/download/$Version/$asset"
    }

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("segul-" + [System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
    try {
      $archive = Join-Path $tmpDir $asset
      Get-Release $url $archive
      Test-Checksum $archive $asset
      Write-Info "Extracting $asset"
      Expand-Archive -Path $archive -DestinationPath $tmpDir -Force
      $newBinary = Join-Path $tmpDir $Binary
      if (-not (Test-Path $newBinary -PathType Leaf)) {
        throw "the archive does not contain $Binary."
      }

      # Run the new binary before replacing anything, so a build that cannot
      # start on this system never overwrites a working install.
      $installedVersion = $null
      try { $installedVersion = & $newBinary --version 2>$null } catch { }
      if (-not $installedVersion -or $LASTEXITCODE -ne 0) {
        throw "the downloaded $Binary does not run on this system. See $DocsUrl for other install options."
      }

      Set-Binary $newBinary $Dir
      Write-Info "Installed $installedVersion to $(Join-Path $Dir $Binary)"
    } finally {
      Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    }

    Update-UserPath $Dir $NoModifyPath.IsPresent
    return $true
  } catch {
    Write-Fail $_.Exception.Message
    return $false
  }
}

function Show-Usage {
  @'
SEGUL CLI installer for Windows

Usage: install.ps1 [-Dir <path>] [-Version <tag>] [-NoModifyPath] [-Uninstall]

  -Dir <path>        Install into <path> instead of ~\.local\bin.
  -Version <tag>     Install a specific release, such as v0.23.2.
  -NoModifyPath      Do not add the install folder to the user PATH.
  -Uninstall         Remove the binary installed by this script.
  -Help              Show this help.

To pass options when piping:

  & ([scriptblock]::Create((irm https://segul.app/install.ps1))) -Dir C:\Tools
'@ | Write-Host
}

function Write-Info([string]$Message) {
  Write-Host '==> ' -ForegroundColor Green -NoNewline
  Write-Host $Message
}

function Write-Warn([string]$Message) {
  Write-Host 'warning: ' -ForegroundColor Yellow -NoNewline
  Write-Host $Message
}

function Write-Fail([string]$Message) {
  Write-Host 'error: ' -ForegroundColor Red -NoNewline
  Write-Host $Message
}

# Returns the release asset name for this CPU.
function Select-Asset {
  # OSArchitecture reports the real CPU even when PowerShell runs as an x64
  # process under emulation on Windows on ARM.
  $arch = $null
  try {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
  } catch { }
  if (-not $arch) {
    $arch = $env:PROCESSOR_ARCHITEW6432
    if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
  }

  switch -Regex ($arch) {
    '^(X64|AMD64)$' { return 'segul-Windows-x86_64.zip' }
    '^(Arm64|ARM64)$' { return 'segul-Windows-arm64.zip' }
    default { throw "no pre-built binary for the $arch CPU. Install with cargo instead: cargo install segul" }
  }
}

function Get-Release([string]$Url, [string]$OutFile) {
  Write-Info "Downloading $Url"
  # Windows PowerShell 5.1 may default to TLS 1.0, which GitHub rejects.
  [Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  try {
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
  } catch {
    $status = 0
    try { $status = [int]$_.Exception.Response.StatusCode } catch { }
    if ($status -eq 404 -and $Version -ne 'latest') {
      throw "release $Version has no $(Split-Path $Url -Leaf). Check the tag at https://github.com/$Repo/releases"
    }
    if ($status -eq 404) {
      throw "the latest release has no $(Split-Path $Url -Leaf). See $DocsUrl for other install options."
    }
    throw "download failed: $Url ($($_.Exception.Message))"
  }
}

# Compares the archive with the SHA-256 digest GitHub records for the release
# asset. A mismatch stops the install. When the digest is unavailable, such as
# for older releases or when the GitHub API is rate limited, the install
# continues with a warning.
function Test-Checksum([string]$Archive, [string]$Asset) {
  if ($Version -eq 'latest') {
    $api = "https://api.github.com/repos/$Repo/releases/latest"
  } else {
    $api = "https://api.github.com/repos/$Repo/releases/tags/$Version"
  }

  $expected = $null
  try {
    $release = Invoke-RestMethod -Uri $api -UseBasicParsing -Headers @{ 'User-Agent' = 'segul-installer' }
    foreach ($item in $release.assets) {
      if ($item.name -eq $Asset -and $item.PSObject.Properties['digest'] -and $item.digest) {
        $expected = ($item.digest -replace '^sha256:', '').ToLowerInvariant()
      }
    }
  } catch { }

  if (-not $expected) {
    Write-Warn "could not get the checksum for $Asset. Skipping verification."
    return
  }

  $actual = (Get-FileHash -Path $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) {
    throw "checksum mismatch for $Asset. Expected $expected, got $actual. Try again."
  }
  Write-Info 'Verified SHA-256 checksum'
}

# Moves the binary into the install folder. A running segul.exe is locked by
# Windows, so that case gets its own message.
function Set-Binary([string]$Source, [string]$InstallDir) {
  try {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  } catch {
    throw "cannot create $InstallDir. Choose another folder with -Dir."
  }
  $target = Join-Path $InstallDir $Binary
  try {
    Move-Item -Path $Source -Destination $target -Force
  } catch [System.UnauthorizedAccessException] {
    throw "cannot write to $InstallDir. Choose another folder with -Dir."
  } catch {
    throw "cannot replace $target. Close any program using segul and try again."
  }
}

# True when a PATH entry points to the folder, ignoring trailing slashes and
# case. Entries may hold variables such as %USERPROFILE%.
function Test-SameFolder([string]$Entry, [string]$InstallDir) {
  if (-not $Entry) { return $false }
  $expanded = [Environment]::ExpandEnvironmentVariables($Entry)
  return $expanded.TrimEnd('\') -ieq $InstallDir.TrimEnd('\')
}

# True when a PATH value lists the folder.
function Test-PathEntry([string]$PathValue, [string]$InstallDir) {
  foreach ($entry in ($PathValue -split ';')) {
    if (Test-SameFolder $entry $InstallDir) { return $true }
  }
  return $false
}

# Reads the user PATH from the registry as stored. The .NET environment API
# would expand entries such as %USERPROFILE%\bin.
function Get-UserPath {
  $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
  if (-not $key) { return '' }
  try {
    $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    return [string]$key.GetValue('Path', '', $options)
  } finally {
    $key.Close()
  }
}

# Writes the user PATH and keeps its registry type, so entries with variables
# keep working.
function Set-UserPath([string]$Value) {
  $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
  try {
    $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    try { $kind = $key.GetValueKind('Path') } catch { }
    $key.SetValue('Path', $Value, $kind)
  } finally {
    $key.Close()
  }

  # A direct registry write sends no change notice. Setting a scratch variable
  # makes Windows tell running programs to reload PATH. Delete it from the
  # registry, since PowerShell 7 keeps a variable that is set to null.
  $notice = 'SEGUL_INSTALL_' + [System.Guid]::NewGuid().ToString('N')
  [Environment]::SetEnvironmentVariable($notice, '1', 'User')
  $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
  try {
    $key.DeleteValue($notice, $false)
  } finally {
    $key.Close()
  }
}

function Update-UserPath([string]$InstallDir, [bool]$SkipModify) {
  if (Test-PathEntry $env:Path $InstallDir) {
    Write-Host "Run 'segul --help' to get started."
    return
  }

  if ($SkipModify) {
    Write-Warn "$InstallDir is not on your PATH."
    Write-Host 'Add it by running:'
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', `"$InstallDir;`" + [Environment]::GetEnvironmentVariable('Path', 'User'), 'User')"
    Write-Host "Then open a new terminal and run 'segul --help'."
    return
  }

  $userPath = Get-UserPath
  if (-not (Test-PathEntry $userPath $InstallDir)) {
    if ($userPath) {
      $userPath = "$InstallDir;$userPath"
    } else {
      $userPath = $InstallDir
    }
    Set-UserPath $userPath
    Write-Info "Added $InstallDir to your user PATH"
  }
  # Also update this session, so segul works without opening a new terminal.
  $env:Path = "$InstallDir;$env:Path"
  Write-Host "Run 'segul --help' to get started. Other open terminals need restarting first."
}

function Remove-Segul([string]$InstallDir) {
  $target = Join-Path $InstallDir $Binary
  if (-not (Test-Path $target -PathType Leaf)) {
    throw "no $Binary found in $InstallDir. Pass -Dir if you installed it elsewhere."
  }
  Write-Info "Removing $target"
  try {
    Remove-Item -Force $target
  } catch {
    throw "cannot remove $target. Close any program using segul and try again."
  }

  # Drop the PATH entry and the folder only when the folder is now empty,
  # since other tools may share it.
  $remaining = @(Get-ChildItem -Force $InstallDir -ErrorAction SilentlyContinue)
  if ($remaining.Count -eq 0) {
    $userPath = Get-UserPath
    if (Test-PathEntry $userPath $InstallDir) {
      $kept = @(($userPath -split ';') | Where-Object { $_ -and -not (Test-SameFolder $_ $InstallDir) })
      Set-UserPath ($kept -join ';')
      Write-Info "Removed $InstallDir from your user PATH"
    }
    Remove-Item -Force $InstallDir -ErrorAction SilentlyContinue
  }
  Write-Host 'SEGUL is uninstalled.'
}

if (-not (Install-Segul -Dir $Dir -Version $Version -NoModifyPath:$NoModifyPath -Uninstall:$Uninstall -Help:$Help)) {
  $global:LASTEXITCODE = 1
  # Empty when the script runs through iex at the prompt.
  if ($PSCommandPath) { exit 1 }
}
