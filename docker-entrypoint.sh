#!/bin/bash
set -euo pipefail

echo "=== ArchInstaller Docker Build ==="

# ─── Backup original profile files ────────────────────────────────────
cp /build/profile/packages.x86_64 /build/profile/packages.x86_64.orig
cp /build/profile/pacman.conf /build/profile/pacman.conf.orig

# ─── Replace 'calamares' with 'calamares-local' in package list ────────
sed -i 's/^calamares$/calamares-local/' /build/profile/packages.x86_64
sed -i '/^calamares-extensions$/d' /build/profile/packages.x86_64

# ─── Create a proper local repo from the cached pkg ───────────────────
REPO_DIR="/tmp/custom-repo"
mkdir -p "$REPO_DIR"
cp /var/cache/pacman/pkg/calamares-local-*.pkg.tar.zst "$REPO_DIR/"
repo-add "$REPO_DIR/custom.db.tar.gz" "$REPO_DIR"/calamares-local-*.pkg.tar.zst

# ─── Add the local repo to profile's pacman.conf ──────────────────────
printf '\n[custom]\nSigLevel = Optional TrustAll\nServer = file://%s\n' "$REPO_DIR" >> /build/profile/pacman.conf

echo "Local repo contents:"
ls -la "$REPO_DIR/"
echo ""
echo "Profile pacman.conf tail:"
tail -5 /build/profile/pacman.conf
echo ""
echo "Starting ISO build..."

# ─── Build the ISO ────────────────────────────────────────────────────
mkarchiso -v -w /tmp/archiso-work -o /build/out /build/profile
EXIT_CODE=$?

# ─── Restore original files ───────────────────────────────────────────
mv /build/profile/packages.x86_64.orig /build/profile/packages.x86_64
mv /build/profile/pacman.conf.orig /build/profile/pacman.conf

exit $EXIT_CODE
