#!/bin/bash
# ArchInstaller — post-install configuration
# Runs OUTSIDE chroot (dontChroot: true)

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

echo "=== ArchInstaller post-install on $TARGET ==="

# ─── Fix timezone symlink ─────────────────────────────────────────────
# Calamares may set an incomplete timezone (e.g. America/Argentina instead
# of America/Argentina/Buenos_Aires). We validate and fix it.
ZONEINFO="$TARGET/usr/share/zoneinfo"
LOCALTIME="$TARGET/etc/localtime"

if [[ -L "$LOCALTIME" ]]; then
    TZ_TARGET=$(readlink "$LOCALTIME")
    TZ_PATH="$TARGET/$TZ_TARGET"
    # If the timezone path is a directory (not a file), it's incomplete
    if [[ -d "$TZ_PATH" ]] || [[ ! -f "$TZ_PATH" ]]; then
        echo "WARNING: Timezone '$TZ_TARGET' is invalid (directory or missing)."
        # Try to find a valid timezone file inside it
        if [[ -d "$TZ_PATH" ]]; then
            FIRST_TZ=$(find "$TZ_PATH" -maxdepth 1 -type f | head -1)
            if [[ -n "$FIRST_TZ" ]]; then
                NEW_TZ="${FIRST_TZ#$TARGET}"
                echo "Auto-fixing timezone to: $NEW_TZ"
                ln -sf "$NEW_TZ" "$LOCALTIME"
            fi
        else
            echo "Falling back to UTC"
            ln -sf /usr/share/zoneinfo/UTC "$LOCALTIME"
        fi
    fi
elif [[ ! -e "$LOCALTIME" ]]; then
    # No localtime set at all — copy from live system
    if [[ -L /etc/localtime ]]; then
        LIVE_TZ=$(readlink /etc/localtime)
        echo "Copying timezone from live system: $LIVE_TZ"
        ln -sf "$LIVE_TZ" "$LOCALTIME"
    else
        echo "Setting timezone to UTC (no timezone configured)"
        ln -sf /usr/share/zoneinfo/UTC "$LOCALTIME"
    fi
fi

# ─── Ensure sudoers is configured for wheel ───────────────────────────
SUDOERS="$TARGET/etc/sudoers"
if [[ -f "$SUDOERS" ]] && grep -q '^# %wheel ALL=(ALL:ALL) ALL' "$SUDOERS"; then
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$SUDOERS"
    echo "Enabled sudo for wheel group."
fi

# ─── Enable color and parallel downloads in pacman ────────────────────
PACMAN_CONF="$TARGET/etc/pacman.conf"
if [[ -f "$PACMAN_CONF" ]]; then
    sed -i 's/^#Color/Color/' "$PACMAN_CONF"
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' "$PACMAN_CONF"
    echo "Enabled pacman Color and ParallelDownloads."
fi

# ─── Run chrooted commands ────────────────────────────────────────────
arch-chroot "$TARGET" /bin/bash -e <<'CHROOTEOF'

# Regenerate initramfs
echo "Regenerating initramfs..."
mkinitcpio -P

# Setup reflector for fast mirrors
if command -v reflector &>/dev/null; then
    echo "Updating pacman mirrorlist with reflector..."
    reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || true
fi

# Install yay (AUR helper) for the new user
NEW_USER=$(awk -F: '$3 >= 1000 && $3 < 60000 {print $1; exit}' /etc/passwd)
if [[ -n "$NEW_USER" ]]; then
    echo "Setting up user: $NEW_USER"
    sudo -u "$NEW_USER" xdg-user-dirs-update 2>/dev/null || true

    echo "Installing yay for user: $NEW_USER"
    sudo -u "$NEW_USER" bash -c '
        cd /tmp
        git clone https://aur.archlinux.org/yay-bin.git 2>/dev/null
        cd yay-bin
        makepkg -si --noconfirm 2>/dev/null
        rm -rf /tmp/yay-bin
    ' || echo "WARNING: yay installation failed (non-fatal)"
fi

CHROOTEOF

echo "=== Post-install complete ==="
