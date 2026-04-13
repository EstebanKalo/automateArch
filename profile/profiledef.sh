#!/usr/bin/env bash
# archiso profile definition for ArchInstaller

iso_name="archinstaller"
iso_label="ARCHINSTALLER_$(date +%Y%m)"
iso_publisher="ArchInstaller <https://github.com/YOUR_USER/archinstaller>"
iso_application="ArchInstaller Live Environment"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
  'uefi-ia32.grub.esp'
  'uefi-x64.grub.esp'
  'uefi-ia32.grub.eltorito'
  'uefi-x64.grub.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/calamares/scripts/pacstrap.sh"]="0:0:755"
  ["/etc/calamares/scripts/post-install.sh"]="0:0:755"
)
