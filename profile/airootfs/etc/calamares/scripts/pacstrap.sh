#!/bin/bash
# ArchInstaller — pacstrap script
# Called by Calamares shellprocess@pacstrap

set -euo pipefail

TARGET="$1"

# If @@ROOT@@ was not substituted, auto-detect the mountpoint
if [[ -z "$TARGET" || "$TARGET" == "@@ROOT@@" || ! -d "$TARGET" ]]; then
    TARGET=$(find /tmp -maxdepth 1 -name "calamares-root-*" -type d 2>/dev/null | head -1)
    if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
        echo "ERROR: Cannot find Calamares target mountpoint"
        exit 1
    fi
    echo "Auto-detected target mountpoint: $TARGET"
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

# ─── Ensure mirrorlist has active mirrors ─────────────────────────────
if ! grep -q '^Server' /etc/pacman.d/mirrorlist; then
    echo "No active mirrors found. Setting up mirrors..."
    if command -v reflector &>/dev/null; then
        reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || \
            sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    else
        sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    fi
    echo "Mirrors configured: $(grep -c '^Server' /etc/pacman.d/mirrorlist) active servers"
fi

# ─── Fix live system pacman.conf (remove custom repo from Docker) ─────
if grep -q '\[custom\]' /etc/pacman.conf; then
    sed -i '/\[custom\]/,/^$/d' /etc/pacman.conf
    echo "Removed [custom] repo from live pacman.conf"
fi

# ─── Initialize pacman keyring on live system if needed ───────────────
if [[ ! -d /etc/pacman.d/gnupg ]] || ! pacman-key --list-keys &>/dev/null; then
    echo "Initializing pacman keyring..."
    pacman-key --init
    pacman-key --populate archlinux
fi

# ─── Run pacstrap ─────────────────────────────────────────────────────
echo "Installing ${#PACKAGES[@]} packages to $TARGET ..."
pacstrap "$TARGET" "${PACKAGES[@]}"

echo "pacstrap completed successfully."

# ─── Ensure directories exist for Calamares modules ───────────────────
mkdir -p "$TARGET/etc/sudoers.d"
chmod 750 "$TARGET/etc/sudoers.d"
echo "Created /etc/sudoers.d in target."
