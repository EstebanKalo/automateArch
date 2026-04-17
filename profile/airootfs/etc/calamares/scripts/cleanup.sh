#!/bin/bash
# ArchInstaller — cleanup script
TARGET=$(find /tmp -maxdepth 1 -name "calamares-root-*" -type d 2>/dev/null | head -1)
if [[ -n "$TARGET" ]]; then
    rm -rf "$TARGET/etc/calamares" 2>/dev/null
    rm -f "$TARGET/etc/sudoers.d/g_wheel_nopasswd" 2>/dev/null
    echo "Cleanup complete on $TARGET"
fi
