#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
SRC_OWNER="A-C-I-D"
SRC_REPO="SEM-V-programs"
SRC_BRANCH="main"
SRC_SUBDIR="LP1"   # change this if needed later

TARBALL_URL="https://codeload.github.com/${SRC_OWNER}/${SRC_REPO}/tar.gz/refs/heads/${SRC_BRANCH}"

# Install directly into Downloads
PREFIX="${HOME}/Downloads"

QUIET=0
FORCE=0

usage() {
  cat <<EOF
Usage: install.sh [--force] [--quiet]

This installer downloads ${SRC_SUBDIR} from the GitHub repo
and installs **directly into your Downloads folder**:

  ${HOME}/Downloads

Options:
  --force       Overwrite existing files
  --quiet       Suppress logs
EOF
}

log() { [ "$QUIET" -eq 1 ] || echo "$@"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }

# Parse flags
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

need curl
need tar
mkdir -p "$PREFIX"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ARCHIVE="$TMPDIR/src.tar.gz"
EXTRACT_DIR="$TMPDIR/extract"

log "⬇️  Downloading ${SRC_SUBDIR}..."
curl -sSL "$TARBALL_URL" -o "$ARCHIVE"

log "📦 Extracting..."
mkdir -p "$EXTRACT_DIR"
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR" --strip-components=2 \
  "${SRC_REPO}-${SRC_BRANCH}/${SRC_SUBDIR}"

log "📁 Installing directly into: $PREFIX"
if [ "$FORCE" -eq 1 ]; then
  cp -Rf "$EXTRACT_DIR"/. "$PREFIX"/
else
  cp -Rn "$EXTRACT_DIR"/. "$PREFIX"/
fi

log "✅ Done!"
log "Files are now located in: $PREFIX"
