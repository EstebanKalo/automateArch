#!/usr/bin/env bash
# archiso profile definition for ArchInstaller

iso_name="archinstaller"
iso_label="ARCHINSTALLER_$(date +%Y%m)"
iso_publisher="ArchInstaller <https://github.com/EstebanKalo/automateArch>"
iso_application="ArchInstaller Live Environment"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux'
  'uefi.grub'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d/00-live-nopasswd"]="0:0:440"
  ["/etc/calamares/scripts/pacstrap.sh"]="0:0:755"
  ["/etc/calamares/scripts/post-install.sh"]="0:0:755"
  ["/etc/calamares/scripts/cleanup.sh"]="0:0:755"
  ["/home/live"]="1000:1000:750"
)
