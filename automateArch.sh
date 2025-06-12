#!/bin/bash
set -e

# Colors
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"

# Header
echo -e "${greenColour} Automatic Arch Linux Installer (Prototype) ${endColour}"

# User input
read -rp "$(echo -e ${blueColour}Installation disk (e.g., /dev/sda or /dev/nvme0n1): ${endColour})" DISK

# Validate disk exists
if [ ! -b "$DISK" ]; then
  echo -e "${redColour}Error: $DISK no es un dispositivo de bloque válido.${endColour}"
  exit 1
fi

# Ask for confirmation before wiping
read -rp "$(echo -e ${yellowColour}WARNING: This will wipe ALL data on $DISK. Type 'YES' to continue: ${endColour})" CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo -e "${redColour}Cancelled.${endColour}"
  exit 1
fi

read -rp "$(echo -e ${blueColour}Hostname: ${endColour})" HOSTNAME
read -rp "$(echo -e ${blueColour}Username: ${endColour})" USERNAME

read -s -rp "$(echo -e ${yellowColour}Password for $USERNAME: ${endColour})" USER_PASS; echo
read -s -rp "$(echo -e ${yellowColour}Confirm password for $USERNAME: ${endColour})" USER_PASS_CONFIRM; echo
[[ "$USER_PASS" != "$USER_PASS_CONFIRM" ]] && { echo -e "${redColour}User passwords do not match.${endColour}"; exit 1; }

read -s -rp "$(echo -e ${yellowColour}Password for root: ${endColour})" ROOT_PASS; echo
read -s -rp "$(echo -e ${yellowColour}Confirm password for root: ${endColour})" ROOT_PASS_CONFIRM; echo
[[ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]] && { echo -e "${redColour}Root passwords do not match.${endColour}"; exit 1; }

# Partition sizes input
echo -e "${yellowColour}Enter partition sizes:${endColour}"
ROOT_SIZE=""
while [[ -z "$ROOT_SIZE" ]]; do
  read -rp "Root partition size (e.g., 40G): " ROOT_SIZE
done

SWAP_SIZE=""
while [[ -z "$SWAP_SIZE" ]]; do
  read -rp "Swap partition size (e.g., 4G): " SWAP_SIZE
done

# Detect if disk uses p suffix (nvme)
if [[ "$DISK" =~ "nvme" ]]; then
  P1="${DISK}p1"
  P2="${DISK}p2"
  P3="${DISK}p3"
  P4="${DISK}p4"
else
  P1="${DISK}1"
  P2="${DISK}2"
  P3="${DISK}3"
  P4="${DISK}4"
fi

# Partitioning

echo -e "${yellowColour}Wiping and partitioning disk: $DISK...${endColour}"
sgdisk --zap-all "$DISK"
sgdisk -o "$DISK"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$DISK"
sgdisk -n 2:0:+${ROOT_SIZE} -t 2:8300 -c 2:"Root" "$DISK"
sgdisk -n 3:0:+${SWAP_SIZE} -t 3:8200 -c 3:"Swap" "$DISK"
sgdisk -n 4:0:0     -t 4:8300 -c 4:"Home" "$DISK"

# Formatting

echo -e "${yellowColour}Formatting partitions...${endColour}"
mkfs.fat -F32 "$P1"
mkfs.ext4 "$P2"
mkfs.ext4 "$P4"
mkswap "$P3"

# Mounting

echo -e "${yellowColour}Mounting partitions...${endColour}"
mount "$P2" /mnt
mkdir -p /mnt/{boot,home}
mount "$P1" /mnt/boot
mount "$P4" /mnt/home
swapon "$P3"

# Base system installation

echo -e "${yellowColour}Installing base system and essential packages...${endColour}"
pacstrap -K /mnt base linux linux-firmware \
    sudo nano git curl wget xdg-user-dirs \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    bash-completion man-db man-pages \
    networkmanager base-devel

genfstab -U /mnt >> /mnt/etc/fstab

# Chroot configuration

echo -e "${yellowColour}Entering chroot environment...${endColour}"

arch-chroot /mnt /bin/bash <<EOF

echo "$HOSTNAME" > /etc/hostname
ln -sf /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

echo "Installing GRUB bootloader..."
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing yay for $USERNAME..."
sudo -u $USERNAME bash -c '
cd /home/$USERNAME
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
'

EOF

# Clean sensitive variables
unset USER_PASS USER_PASS_CONFIRM ROOT_PASS ROOT_PASS_CONFIRM

echo -e "${greenColour}Installation completed successfully. You can now reboot your system.${endColour}"

