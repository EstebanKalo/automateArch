#!/bin/bash
set -e

# Colors
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"

echo -e "${greenColour}=== Automatic Arch Linux Installer ===${endColour}"

read -rp "$(echo -e ${blueColour}Installation disk (e.g., /dev/sda or /dev/nvme0n1): ${endColour})" DISK
read -rp "$(echo -e ${blueColour}Hostname: ${endColour})" HOSTNAME
read -rp "$(echo -e ${blueColour}Username: ${endColour})" USERNAME

read -s -rp "$(echo -e ${yellowColour}Password for $USERNAME: ${endColour})" USER_PASS; echo
read -s -rp "$(echo -e ${yellowColour}Confirm password for $USERNAME: ${endColour})" USER_PASS_CONFIRM; echo
[[ "$USER_PASS" != "$USER_PASS_CONFIRM" ]] && { echo -e "${redColour}User passwords do not match.${endColour}"; exit 1; }

read -s -rp "$(echo -e ${yellowColour}Password for root: ${endColour})" ROOT_PASS; echo
read -s -rp "$(echo -e ${yellowColour}Confirm password for root: ${endColour})" ROOT_PASS_CONFIRM; echo
[[ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]] && { echo -e "${redColour}Root passwords do not match.${endColour}"; exit 1; }

echo -e "${yellowColour}Wiping and partitioning disk: $DISK...${endColour}"
sgdisk --zap-all "$DISK"
sgdisk -o "$DISK"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$DISK"
sgdisk -n 2:0:+40G  -t 2:8300 -c 2:"Root" "$DISK"
sgdisk -n 3:0:+4G   -t 3:8200 -c 3:"Swap" "$DISK"
sgdisk -n 4:0:0     -t 4:8300 -c 4:"Home" "$DISK"

sleep 2

echo -e "${yellowColour}Formatting partitions...${endColour}"
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "${DISK}4"
mkswap "${DISK}3"

echo -e "${yellowColour}Mounting partitions...${endColour}"
mount "${DISK}2" /mnt
mkdir -p /mnt/{boot,home}
mount "${DISK}1" /mnt/boot
mount "${DISK}4" /mnt/home
swapon "${DISK}3"

echo -e "${yellowColour}Installing base system and essential packages...${endColour}"
pacstrap -K /mnt base linux linux-firmware \
    sudo nano git curl wget xdg-user-dirs \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    bash-completion man-db man-pages \
    networkmanager base-devel

genfstab -U /mnt >> /mnt/etc/fstab

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

echo -e "${greenColour}Installation completed successfully. You can now reboot your system.${endColour}"
