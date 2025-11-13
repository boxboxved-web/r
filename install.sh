#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
SRC_OWNER="A-C-I-D"
SRC_REPO="SEM-V-programs"
SRC_BRANCH="main"
SRC_SUBDIR="LP1"
TARBALL_URL="https://codeload.github.com/${SRC_OWNER}/${SRC_REPO}/tar.gz/refs/heads/${SRC_BRANCH}"

# Default prefix (root Downloads)
DEFAULT_PREFIX="/root/Downloads/LP1"

# === Flags ===
PREFIX="$DEFAULT_PREFIX"
QUIET=0
FORCE=0

usage() {
  cat <<EOF
Usage: install.sh [--prefix DIR] [--force] [--quiet]

Downloads ${SRC_SUBDIR} from ${SRC_OWNER}/${SRC_REPO} into DIR.
Defaults to: ${DEFAULT_PREFIX}

Options:
  --prefix DIR   Custom destination directory
  --force        Overwrite existing files
  --quiet        Suppress logs
  -h, --help     Show this help message
EOF
}

log() { [ "$QUIET" -eq 1 ] || echo "$@"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }

# === Parse arguments ===
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# === Requirements ===
need curl
need tar
mkdir -p "$PREFIX"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ARCHIVE="$TMPDIR/source.tar.gz"
EXTRACT_DIR="$TMPDIR/extract"

log "⬇️  Downloading LP1 folder from GitHub..."
curl -sSL "$TARBALL_URL" -o "$ARCHIVE"

log "📦 Extracting ${SRC_SUBDIR}..."
mkdir -p "$EXTRACT_DIR"
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR" --strip-components=2 "${SRC_REPO}-${SRC_BRANCH}/${SRC_SUBDIR}"

log "📁 Installing to: $PREFIX"
if [ "$FORCE" -eq 1 ]; then
  cp -Rf "$EXTRACT_DIR"/. "$PREFIX"/
else
  cp -Rn "$EXTRACT_DIR"/. "$PREFIX"/
fi

log "✅ Installation complete!"
log "📍 Files available in: $PREFIX"
