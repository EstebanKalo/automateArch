#!/bin/bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────
GREEN="\e[1;32m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
RESET="\e[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="archinstaller-builder"
CONTAINER_NAME="archinstaller-build-$$"

# ─── Detect container runtime ─────────────────────────────────────────
if command -v docker &>/dev/null; then
    RUNTIME="docker"
elif command -v podman &>/dev/null; then
    RUNTIME="podman"
else
    echo -e "${RED}Error: Necesitás docker o podman instalado.${RESET}"
    echo "  Ubuntu/Debian:  sudo apt install docker.io"
    echo "  Fedora:         sudo dnf install podman"
    echo "  Arch:           sudo pacman -S docker"
    exit 1
fi

echo -e "${BLUE}Usando runtime: ${RUNTIME}${RESET}"

# ─── Build the builder image ──────────────────────────────────────────
echo -e "${YELLOW}Construyendo imagen del builder (primera vez tarda ~2-5 min)...${RESET}"
$RUNTIME build -t "$IMAGE_NAME" "$SCRIPT_DIR"

# ─── Create output directory ──────────────────────────────────────────
mkdir -p "$SCRIPT_DIR/out"

# ─── Run the build ────────────────────────────────────────────────────
echo -e "${YELLOW}Buildeando la ISO dentro del contenedor...${RESET}"
echo -e "${BLUE}Esto puede tardar 10-30 minutos dependiendo de tu conexión.${RESET}"

$RUNTIME run --rm \
    --name "$CONTAINER_NAME" \
    --privileged \
    -v "$SCRIPT_DIR":/build:z \
    "$IMAGE_NAME"

# ─── Result ───────────────────────────────────────────────────────────
ISO_FILE=$(ls "$SCRIPT_DIR/out/"*.iso 2>/dev/null | head -1)

if [[ -n "$ISO_FILE" ]]; then
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}  ISO generada exitosamente!${RESET}"
    echo -e "${GREEN}  Archivo: ${ISO_FILE}${RESET}"
    echo -e "${GREEN}  Tamaño:  ${ISO_SIZE}${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "${BLUE}Para testear en QEMU:${RESET}"
    echo "  qemu-img create -f qcow2 /tmp/test-disk.qcow2 20G"
    echo "  qemu-system-x86_64 -enable-kvm -m 4G \\"
    echo "    -bios /usr/share/ovmf/x64/OVMF.fd \\"
    echo "    -cdrom ${ISO_FILE} \\"
    echo "    -drive file=/tmp/test-disk.qcow2,format=qcow2 -boot d"
    echo ""
    echo -e "${BLUE}Para grabar en USB:${RESET}"
    echo "  sudo dd bs=4M if=${ISO_FILE} of=/dev/sdX status=progress oflag=sync"
else
    echo -e "${RED}Error: No se encontró la ISO en out/. Revisá los logs arriba.${RESET}"
    exit 1
fi
