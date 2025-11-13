#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# Configuration (edit if needed)
# -------------------------
SRC_OWNER="A-C-I-D"
SRC_REPO="SEM-V-programs"
SRC_BRANCH="main"
# Subdirectory inside the repo to extract (default: LP1)
SRC_SUBDIR="LP1"
TARBALL_URL="https://codeload.github.com/${SRC_OWNER}/${SRC_REPO}/tar.gz/refs/heads/${SRC_BRANCH}"
# -------------------------

# Flags (will be set by args)
PREFIX=""
PREFIX_SET=0
QUIET=0
FORCE=0

usage() {
  cat <<EOF
Usage: install.sh [--prefix DIR] [--force] [--quiet] [-h|--help]

Downloads ${SRC_SUBDIR} from ${SRC_OWNER}/${SRC_REPO} and installs files.

Defaults:
  - If run normally:     \$HOME/Downloads
  - If run with sudo:    /home/<original-user>/Downloads   (so we DON'T write into /root by default)

Options:
  --prefix DIR    Install destination directory
  --force         Overwrite existing files
  --quiet         Suppress log output
  -h, --help      Show this help
EOF
}

log() { [ "$QUIET" -eq 1 ] || echo "$@"; }

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)
      if [ $# -lt 2 ]; then
        echo "Error: --prefix requires an argument" >&2
        exit 1
      fi
      PREFIX="$2"
      PREFIX_SET=1
      shift 2
      ;;
    --force) FORCE=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# Determine sensible default PREFIX:
# - Prefer explicit --prefix
# - If running under sudo, prefer the original user's home (SUDO_USER)
# - Otherwise use $HOME
if [ "$PREFIX_SET" -eq 0 ]; then
  if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    # original non-root user invoked sudo; install into their Downloads
    PREFIX="/home/${SUDO_USER}/Downloads"
  else
    PREFIX="${HOME}/Downloads"
  fi
fi

# Validate tools
need curl
need tar
need mkdir

# Create destination
mkdir -p "$PREFIX"

# Workspace
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ARCHIVE="$TMPDIR/source.tar.gz"
EXTRACT_DIR="$TMPDIR/extract"

log "⬇️  Downloading ${SRC_OWNER}/${SRC_REPO} (${SRC_BRANCH})..."
curl -sSL "$TARBALL_URL" -o "$ARCHIVE"

log "📦 Extracting ${SRC_SUBDIR}..."
mkdir -p "$EXTRACT_DIR"

# Ensure the path exists in the archive, extract only that folder (strip leading components)
# The archive's top-level folder is: ${SRC_REPO}-${SRC_BRANCH}/...
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR" --strip-components=2 "${SRC_REPO}-${SRC_BRANCH}/${SRC_SUBDIR}"

log "📁 Installing into: $PREFIX"
if [ "$FORCE" -eq 1 ]; then
  cp -Rf "$EXTRACT_DIR"/. "$PREFIX"/
else
  # copy without overwriting existing files
  cp -Rn "$EXTRACT_DIR"/. "$PREFIX"/
fi

log "✅ Done. Files installed to: $PREFIX"
