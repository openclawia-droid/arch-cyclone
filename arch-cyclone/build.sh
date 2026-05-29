#!/usr/bin/env bash
# build.sh - Build Arch-Cyclone ISO using archiso
#
# Usage: sudo ./build.sh
#
# Requirements:
#   - archiso package installed (pkgname: archiso)
#   - root privileges
#   - ~8GB free disk space

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/Profile"
OUT_DIR="$SCRIPT_DIR/out"

# ── Color output ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*" >&2; }

# ── Checks ───────────────────────────────────────────────────────────────────
info "Arch-Cyclone ISO builder"

if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root."
    error "Usage: sudo $0"
    exit 1
fi

if ! command -v mkarchiso &>/dev/null; then
    error "archiso is not installed."
    error "Run: pacman -S archiso"
    exit 1
fi

if [ ! -d "$PROFILE_DIR" ]; then
    error "Profile directory not found at: $PROFILE_DIR"
    exit 1
fi

# ── Output directory ──────────────────────────────────────────────────────────
mkdir -p "$OUT_DIR"
ok "Output directory: $OUT_DIR"

# ── Build ────────────────────────────────────────────────────────────────────
info "Starting ISO build..."
info "Profile: $PROFILE_DIR"
info "Output: $OUT_DIR"
echo ""

mkarchiso -v -w "$OUT_DIR/work" -o "$OUT_DIR" "$PROFILE_DIR"

ISO_FILE="$(ls -t "$OUT_DIR"/arch-cyclone-*.iso 2>/dev/null | head -1)"
if [ -n "$ISO_FILE" ]; then
    SIZE=$(du -h "$ISO_FILE" | cut -f1)
    ok "Build complete!"
    ok "ISO: $ISO_FILE"
    ok "Size: $SIZE"
else
    error "Build completed but no ISO found in $OUT_DIR"
    exit 1
fi