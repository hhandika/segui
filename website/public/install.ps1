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
# cut short cannot execute half a script. Errors are thrown, never `exit`,
# because `exit` would close the terminal when the script runs through iex.

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
    return
  }

  if (-not $Dir) { $Dir = $env:SEGUL_INSTALL_DIR }
  if (-not $Dir) { $Dir = Join-Path $HOME '.local\bin' }
  if (-not $Version) { $Version = $env:SEGUL_VERSION }
  if (-not $Version) { $Version = 'latest' }

  # Resolve ~ and relative paths against the current PowerShell location.
  $Dir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Dir)

  try {
    if ($Uninstall) {
      Remove-Segul $Dir
      return
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
  } catch {
    Write-Fail $_.Exception.Message
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
    throw "download failed: $Url"
  }
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

# True when a PATH value lists the folder, ignoring trailing slashes and case.
function Test-PathEntry([string]$PathValue, [string]$InstallDir) {
  $wanted = $InstallDir.TrimEnd('\')
  foreach ($entry in ($PathValue -split ';')) {
    if ($entry -and $entry.TrimEnd('\') -ieq $wanted) { return $true }
  }
  return $false
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

  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not (Test-PathEntry $userPath $InstallDir)) {
    if ($userPath) {
      $userPath = "$InstallDir;$userPath"
    } else {
      $userPath = $InstallDir
    }
    [Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
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

  # Drop the PATH entry only when the folder is now empty, since other tools
  # may share it.
  $remaining = @(Get-ChildItem -Force $InstallDir -ErrorAction SilentlyContinue)
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($remaining.Count -eq 0 -and (Test-PathEntry $userPath $InstallDir)) {
    $wanted = $InstallDir.TrimEnd('\')
    $kept = ($userPath -split ';') | Where-Object { $_ -and $_.TrimEnd('\') -ine $wanted }
    [Environment]::SetEnvironmentVariable('Path', ($kept -join ';'), 'User')
    Write-Info "Removed $InstallDir from your user PATH"
  }
  Write-Host 'SEGUL is uninstalled.'
}

Install-Segul -Dir $Dir -Version $Version -NoModifyPath:$NoModifyPath -Uninstall:$Uninstall -Help:$Help
