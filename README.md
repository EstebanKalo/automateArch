# ArchInstaller — Arch Linux GUI Installer ISO

A custom Arch Linux live ISO with [Calamares](https://calamares.io/) as a graphical installer.
Boots into a lightweight Xfce desktop where the user launches Calamares to install a **clean, minimal Arch Linux system** — functional and ready to personalize.

## Philosophy

- **Minimal and unopinionated**: installs `base`, `linux`, `linux-firmware`, networking, sudo, and a bootloader. Nothing else.
- **The user decides**: no pre-installed DE, no theming, no bloat. The installed system is a blank canvas.
- **Familiar UX**: Calamares provides the same GUI installer experience as Manjaro, EndeavourOS, etc.

## What gets installed

| Component         | Choice                          |
|-------------------|---------------------------------|
| Kernel            | `linux` (latest stable)         |
| Bootloader        | GRUB (EFI + BIOS)              |
| Network           | NetworkManager                  |
| Shell             | bash                            |
| Init              | systemd                         |
| AUR helper        | yay (optional, enabled by default) |
| Microcode         | Auto-detected (AMD / Intel)     |

## Requirements

To **build** the ISO you need an existing Arch Linux system (or any arch-based distro) with:

- `archiso` (official ISO build tool)
- `git`
- Root privileges
- ~6 GB of free disk space
- Internet connection

## Building the ISO

```bash
git clone https://github.com/YOUR_USER/archinstaller.git
cd archinstaller
sudo ./build.sh
```

The ISO will be output to `./out/`.

### Build options

```bash
sudo ./build.sh --no-yay        # Skip yay installation in target system
sudo ./build.sh --clean          # Remove work directory before building
```

## Burning the ISO

```bash
# USB drive (replace /dev/sdX)
sudo dd bs=4M if=out/archinstaller-*.iso of=/dev/sdX status=progress oflag=sync

# Or use ventoy, balenaEtcher, etc.
```

## How it works

1. User boots the ISO → auto-login to a live Xfce session
2. Double-click "Install Arch Linux" on the desktop (or it auto-launches)
3. Calamares walks through: Language → Keyboard → Partitioning → User setup → Install
4. Behind the scenes, Calamares runs `pacstrap` to install a fresh Arch system (no image extraction)
5. Post-install scripts handle: fstab, locale, bootloader, microcode, user creation, service enablement
6. Reboot into a clean, minimal Arch installation

## Project Structure

```
archinstaller/
├── build.sh                          # ISO build script
├── README.md
└── profile/
    ├── profiledef.sh                 # archiso profile definition
    ├── packages.x86_64               # Packages for the LIVE environment
    ├── pacman.conf                   # pacman.conf used during ISO build
    └── airootfs/                     # Overlay for the live filesystem
        └── etc/
            ├── calamares/
            │   ├── settings.conf     # Calamares main config (module sequence)
            │   ├── branding/         # UI branding (name, logo, colors)
            │   ├── modules/          # Per-module configuration
            │   └── scripts/          # Shell scripts called by Calamares
            ├── skel/Desktop/         # Desktop shortcut for installer
            ├── systemd/system/       # Auto-login config
            └── xdg/autostart/        # Auto-launch Calamares on login
```

## Customization

### Change installed packages

Edit `profile/airootfs/etc/calamares/scripts/pacstrap.sh` — the `PACKAGES` array defines what gets installed on the target system.

### Change branding

Edit `profile/airootfs/etc/calamares/branding/archinstaller/branding.desc` for names, descriptions, and colors.

### Add a post-install hook

Edit `profile/airootfs/etc/calamares/scripts/post-install.sh` to add commands that run inside the installed system (via arch-chroot).

## License

MIT

## Credits

- [Arch Linux](https://archlinux.org/) and [archiso](https://wiki.archlinux.org/title/Archiso)
- [Calamares](https://calamares.io/) installer framework
- Inspired by EndeavourOS and Manjaro's installer workflows
