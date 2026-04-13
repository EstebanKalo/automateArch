#!/bin/bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────
GREEN="\e[1;32m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
RESET="\e[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/profile"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"

INSTALL_YAY=true
DO_CLEAN=false

# ─── Parse arguments ──────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --no-yay)   INSTALL_YAY=false ;;
    --clean)    DO_CLEAN=true ;;
    --help|-h)
      echo "Usage: sudo ./build.sh [--no-yay] [--clean]"
      echo "  --no-yay   Don't include yay AUR helper in the installed system"
      echo "  --clean    Remove work directory before building"
      exit 0
      ;;
    *) echo -e "${RED}Unknown option: $arg${RESET}"; exit 1 ;;
  esac
done

# ─── Preflight checks ────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Error: This script must be run as root.${RESET}"
  exit 1
fi

for cmd in mkarchiso pacman; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Error: '$cmd' not found. Install 'archiso' first:${RESET}"
    echo "  pacman -S archiso"
    exit 1
  fi
done

# ─── Clean if requested ──────────────────────────────────────────────
if $DO_CLEAN; then
  echo -e "${YELLOW}Cleaning previous build artifacts...${RESET}"
  rm -rf "$WORK_DIR" "$OUT_DIR"
fi

# ─── Configure yay toggle ────────────────────────────────────────────
# Write a flag file that the pacstrap script reads
if $INSTALL_YAY; then
  echo "true" > "$PROFILE_DIR/airootfs/etc/calamares/scripts/.install_yay"
else
  echo "false" > "$PROFILE_DIR/airootfs/etc/calamares/scripts/.install_yay"
fi

# ─── Setup Chaotic-AUR for Calamares packages ────────────────────────
# Calamares is not in official Arch repos; we use Chaotic-AUR.
# This adds the keys to the BUILD HOST so mkarchiso can pull packages.

echo -e "${BLUE}Setting up Chaotic-AUR repository (for Calamares)...${RESET}"

if ! pacman-key --list-keys 2>/dev/null | grep -q "3056513887B78AEB"; then
  pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key 3056513887B78AEB
fi

if [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
  pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
fi

# Ensure chaotic-aur is in host pacman.conf temporarily for the build
CHAOTIC_MARKER="# archinstaller-chaotic-aur"
if ! grep -q "$CHAOTIC_MARKER" /etc/pacman.conf 2>/dev/null; then
  echo -e "\n${CHAOTIC_MARKER}\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
  ADDED_CHAOTIC=true
else
  ADDED_CHAOTIC=false
fi

cleanup_chaotic() {
  if $ADDED_CHAOTIC; then
    sed -i "/${CHAOTIC_MARKER}/,+2d" /etc/pacman.conf
    echo -e "${BLUE}Cleaned up Chaotic-AUR from host pacman.conf.${RESET}"
  fi
}
trap cleanup_chaotic EXIT

pacman -Sy --noconfirm

# ─── Build ISO ────────────────────────────────────────────────────────
echo -e "${GREEN}Building ArchInstaller ISO...${RESET}"
echo -e "${BLUE}  Profile:  $PROFILE_DIR${RESET}"
echo -e "${BLUE}  Work dir: $WORK_DIR${RESET}"
echo -e "${BLUE}  Output:   $OUT_DIR${RESET}"

mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}  ISO built successfully!${RESET}"
echo -e "${GREEN}  Output: $(ls "$OUT_DIR"/*.iso 2>/dev/null || echo "$OUT_DIR/")${RESET}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
