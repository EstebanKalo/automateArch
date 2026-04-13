#!/bin/bash
# ArchInstaller — pacstrap script
# Called by Calamares shellprocess@pacstrap
# Argument: $1 = target mountpoint (@@ROOT@@)

set -euo pipefail

TARGET="$1"

if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
    echo "ERROR: Invalid target mountpoint: '$TARGET'"
    exit 1
fi

# ─── Base packages (always installed) ─────────────────────────────────
PACKAGES=(
    # Core
    base
    linux
    linux-firmware
    linux-headers
    mkinitcpio

    # Bootloader
    grub
    efibootmgr
    os-prober

    # Networking
    networkmanager
    dhcpcd

    # System utilities
    sudo
    nano
    git
    curl
    wget
    bash-completion
    man-db
    man-pages
    base-devel
    reflector

    # Filesystem tools
    dosfstools
    e2fsprogs
    btrfs-progs
    xfsprogs
    ntfs-3g

    # User directories
    xdg-user-dirs
    xdg-utils
)

# ─── Detect CPU and add microcode ─────────────────────────────────────
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
case "$CPU_VENDOR" in
    GenuineIntel) PACKAGES+=(intel-ucode); echo "Detected Intel CPU — adding intel-ucode" ;;
    AuthenticAMD) PACKAGES+=(amd-ucode);   echo "Detected AMD CPU — adding amd-ucode"   ;;
    *)            echo "Unknown CPU vendor: $CPU_VENDOR — skipping microcode" ;;
esac

# ─── Detect if running in a VM ────────────────────────────────────────
VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
case "$VIRT" in
    oracle)     PACKAGES+=(virtualbox-guest-utils); echo "Detected VirtualBox VM" ;;
    vmware)     PACKAGES+=(open-vm-tools);          echo "Detected VMware VM" ;;
    kvm|qemu)   PACKAGES+=(qemu-guest-agent);       echo "Detected KVM/QEMU VM" ;;
    microsoft)  PACKAGES+=(hyperv);                 echo "Detected Hyper-V VM" ;;
    *)          echo "Not a recognized VM (or bare metal): $VIRT" ;;
esac

# ─── Run pacstrap ─────────────────────────────────────────────────────
echo "Installing ${#PACKAGES[@]} packages to $TARGET ..."
pacstrap -K "$TARGET" "${PACKAGES[@]}"

echo "pacstrap completed successfully."
