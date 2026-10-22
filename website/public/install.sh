#!/bin/sh
# SEGUL CLI installer for Linux and macOS.
#
#   curl -fsSL https://segul.app/install.sh | sh
#
# Downloads the pre-built `segul` binary for this system from the latest GitHub
# release and installs it to ~/.local/bin, which needs no root access. On
# Linux x86_64 it picks the glibc build when glibc 2.34 or later is present and
# the fully static musl build otherwise, which suits older HPC clusters.
#
# Options, passed after `sh -s --` when piping:
#
#   --dir <path>       Install into <path> instead of ~/.local/bin.
#   --version <tag>    Install a specific release, such as v0.23.2.
#   --musl             Use the static Linux build even when glibc is new enough.
#   --uninstall        Remove the binary installed by this script.
#   -h, --help         Show this help.
#
# For example: curl -fsSL https://segul.app/install.sh | sh -s -- --dir /opt/bin
#
# The same options can be set through SEGUL_INSTALL_DIR=<path>,
# SEGUL_VERSION=<tag>, and SEGUL_LINUX_LIBC=musl.

# Everything runs from main, called on the last line, so a download cut short
# mid-pipe cannot execute half a script.

set -eu

REPO="hhandika/segul"
BINARY="segul"
MIN_GLIBC="2.34"
DOCS_URL="https://segul.app/docs/installation/intro/"

# Color only when writing to a terminal.
if [ -t 2 ]; then
  GREEN=$(printf '\033[1;32m') YELLOW=$(printf '\033[1;33m')
  RED=$(printf '\033[1;31m') RESET=$(printf '\033[0m')
else
  GREEN="" YELLOW="" RED="" RESET=""
fi

info() { printf '%s==>%s %s\n' "$GREEN" "$RESET" "$*" >&2; }
warn() { printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die() {
  printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
SEGUL CLI installer for Linux and macOS

Usage: install.sh [--dir <path>] [--version <tag>] [--musl] [--uninstall]

  --dir <path>       Install into <path> instead of ~/.local/bin.
  --version <tag>    Install a specific release, such as v0.23.2.
  --musl             Use the static Linux build even when glibc is new enough.
  --uninstall        Remove the binary installed by this script.
  -h, --help         Show this help.

When piping, pass options after `sh -s --`:

  curl -fsSL https://segul.app/install.sh | sh -s -- --dir /opt/bin
EOF
}

main() {
  install_dir="${SEGUL_INSTALL_DIR:-$HOME/.local/bin}"
  version="${SEGUL_VERSION:-latest}"
  libc="${SEGUL_LINUX_LIBC:-auto}"
  action="install"

  while [ $# -gt 0 ]; do
    case "$1" in
      --dir)
        [ $# -ge 2 ] || die "--dir needs a path"
        install_dir="$2"
        shift
        ;;
      --version)
        [ $# -ge 2 ] || die "--version needs a release tag, such as v0.23.2"
        version="$2"
        shift
        ;;
      --musl) libc="musl" ;;
      --uninstall) action="uninstall" ;;
      -h | --help)
        usage
        return
        ;;
      *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
  done

  # Expand a leading ~ that was quoted and so skipped by the shell.
  case "$install_dir" in
    "~") install_dir="$HOME" ;;
    "~/"*) install_dir="$HOME/${install_dir#"~/"}" ;;
  esac

  if [ "$action" = "uninstall" ]; then
    uninstall
    return
  fi

  need tar
  need uname
  asset="$(select_asset)"

  if [ "$version" = "latest" ]; then
    url="https://github.com/$REPO/releases/latest/download/$asset"
  else
    url="https://github.com/$REPO/releases/download/$version/$asset"
  fi

  tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t segul)"
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM

  download "$url" "$tmp_dir/$asset"
  info "Extracting $asset"
  tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"
  [ -f "$tmp_dir/$BINARY" ] || die "the archive does not contain the $BINARY executable."
  chmod 755 "$tmp_dir/$BINARY"

  # Run the new binary before replacing anything, so a build that cannot start
  # on this system never overwrites a working install.
  installed_version="$("$tmp_dir/$BINARY" --version 2>/dev/null)" ||
    die "the downloaded $BINARY does not run on this system. See $DOCS_URL for other install options."

  place_binary "$tmp_dir/$BINARY"
  info "Installed $installed_version to $install_dir/$BINARY"
  check_path
}

# Prints the release asset name for this operating system and CPU.
select_asset() {
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$arch" in
    x86_64 | amd64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) die "no pre-built binary for the $arch CPU. Install with cargo instead: cargo install segul" ;;
  esac

  case "$os" in
    Darwin)
      # A shell running under Rosetta reports x86_64 on Apple silicon; the
      # native build is faster.
      if [ "$arch" = "x86_64" ] &&
        [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
        arch="arm64"
      fi
      echo "segul-macOS-$arch.tar.gz"
      ;;
    Linux) select_linux_asset "$arch" ;;
    MINGW* | MSYS* | CYGWIN*)
      die "this installer is for Linux and macOS. On Windows, download segul-Windows-x86_64.zip from https://github.com/$REPO/releases/latest or see $DOCS_URL"
      ;;
    *) die "no pre-built binary for $os. See $DOCS_URL for other install options." ;;
  esac
}

select_linux_asset() {
  arch="$1"
  glibc="$(glibc_version)"

  if [ "$arch" = "arm64" ]; then
    if [ -z "$glibc" ] || ! version_at_least "$glibc" "$MIN_GLIBC"; then
      die "the Linux ARM64 build needs glibc $MIN_GLIBC or later. Install with cargo or conda instead; see $DOCS_URL"
    fi
    echo "segul-Linux-arm64.tar.gz"
    return
  fi

  if [ "$libc" = "musl" ]; then
    echo "segul-Linux-musl-x86_64.tar.gz"
  elif [ -n "$glibc" ] && version_at_least "$glibc" "$MIN_GLIBC"; then
    echo "segul-Linux-x86_64.tar.gz"
  else
    info "glibc ${glibc:-not found} is older than $MIN_GLIBC; using the static musl build"
    echo "segul-Linux-musl-x86_64.tar.gz"
  fi
}

# Prints the glibc version, or nothing on musl systems such as Alpine.
glibc_version() {
  found="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')" || true
  if [ -z "$found" ] && command -v ldd >/dev/null 2>&1; then
    found="$(ldd --version 2>&1 | awk 'NR == 1 && /GNU|GLIBC/ {print $NF}')" || true
  fi
  printf '%s' "$found"
}

# True when dotted version $1 is greater than or equal to $2.
version_at_least() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -n 1)" = "$2" ]
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed."
}

download() {
  info "Downloading $1"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --progress-bar -o "$2" "$1" || die "download failed: $1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$2" "$1" 2>/dev/null || wget -q -O "$2" "$1" ||
      die "download failed: $1"
  else
    die "curl or wget is required to download SEGUL."
  fi
}

# Copies the binary into the install directory, using sudo only when that
# directory is not writable by the current user.
place_binary() {
  if mkdir -p "$install_dir" 2>/dev/null && [ -w "$install_dir" ]; then
    mv -f "$1" "$install_dir/$BINARY"
  elif command -v sudo >/dev/null 2>&1; then
    info "$install_dir is not writable; using sudo"
    sudo mkdir -p "$install_dir"
    sudo mv -f "$1" "$install_dir/$BINARY"
  else
    die "cannot write to $install_dir. Choose another folder with --dir."
  fi
}

check_path() {
  case ":$PATH:" in
    *":$install_dir:"*)
      echo "Run 'segul --help' to get started."
      return
      ;;
  esac

  case "${SHELL:-}" in
    */zsh) profile="~/.zshrc" ;;
    */bash) profile="~/.bashrc" ;;
    */fish) profile="" ;;
    *) profile="~/.profile" ;;
  esac

  warn "$install_dir is not on your PATH."
  if [ -z "$profile" ]; then
    echo "Add it with: fish_add_path $install_dir"
  else
    echo "Add it by running:"
    echo "  echo 'export PATH=\"$install_dir:\$PATH\"' >> $profile"
    echo "Then open a new terminal and run 'segul --help'."
  fi
}

uninstall() {
  target="$install_dir/$BINARY"
  [ -e "$target" ] || die "no $BINARY found in $install_dir. Pass --dir if you installed it elsewhere."
  info "Removing $target"
  if [ -w "$install_dir" ]; then
    rm -f "$target"
  else
    sudo rm -f "$target"
  fi
  echo "SEGUL is uninstalled."
}

main "$@"
