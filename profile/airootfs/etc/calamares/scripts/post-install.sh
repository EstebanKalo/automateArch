#!/bin/bash
# ArchInstaller — post-install configuration
# Runs inside chroot of the installed system
# Called by Calamares shellprocess@post_install

set -euo pipefail

echo "=== ArchInstaller post-install ==="

# ─── Ensure sudoers is configured for wheel ───────────────────────────
SUDOERS="/etc/sudoers"
if grep -q '^# %wheel ALL=(ALL:ALL) ALL' "$SUDOERS"; then
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$SUDOERS"
    echo "Enabled sudo for wheel group."
fi

# ─── Regenerate initramfs ─────────────────────────────────────────────
echo "Regenerating initramfs..."
mkinitcpio -P

# ─── Setup reflector for fast mirrors ─────────────────────────────────
if command -v reflector &>/dev/null; then
    echo "Updating pacman mirrorlist with reflector..."
    reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || true
fi

# ─── Enable color and parallel downloads in pacman ────────────────────
PACMAN_CONF="/etc/pacman.conf"
sed -i 's/^#Color/Color/' "$PACMAN_CONF"
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' "$PACMAN_CONF"

# ─── Install yay (AUR helper) if enabled ──────────────────────────────
INSTALL_YAY_FLAG="/etc/calamares/scripts/.install_yay"
if [[ -f "$INSTALL_YAY_FLAG" ]] && grep -qi "true" "$INSTALL_YAY_FLAG"; then
    # Find the non-root user created by Calamares
    NEW_USER=$(awk -F: '$3 >= 1000 && $3 < 60000 {print $1; exit}' /etc/passwd)
    if [[ -n "$NEW_USER" ]]; then
        echo "Installing yay for user: $NEW_USER"
        sudo -u "$NEW_USER" bash -c '
            cd /tmp
            git clone https://aur.archlinux.org/yay-bin.git
            cd yay-bin
            makepkg -si --noconfirm
            rm -rf /tmp/yay-bin
        ' || echo "WARNING: yay installation failed (non-fatal)"
    fi
fi

# ─── Generate user directories ────────────────────────────────────────
NEW_USER=$(awk -F: '$3 >= 1000 && $3 < 60000 {print $1; exit}' /etc/passwd)
if [[ -n "$NEW_USER" ]]; then
    sudo -u "$NEW_USER" xdg-user-dirs-update || true
fi

echo "=== Post-install complete ==="
