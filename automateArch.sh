#!/bin/bash

set -e

echo "=== Instalador automático de Arch Linux ==="

read -rp "Disco de instalación (ej: /dev/sda o /dev/nvme0n1): " DISK
read -rp "Nombre del equipo (hostname): " HOSTNAME
read -rp "Nombre del usuario: " USERNAME

read -s -rp "Contraseña para $USERNAME: " USER_PASS; echo
read -s -rp "Confirmar contraseña para $USERNAME: " USER_PASS_CONFIRM; echo
[[ "$USER_PASS" != "$USER_PASS_CONFIRM" ]] && { echo "Las contraseñas de usuario no coinciden."; exit 1; }

read -s -rp "Contraseña para root: " ROOT_PASS; echo
read -s -rp "Confirmar contraseña para root: " ROOT_PASS_CONFIRM; echo
[[ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]] && { echo "Las contraseñas de root no coinciden."; exit 1; }

echo "Erasing and cleaning up: $DISK ==="
sgdisk --zap-all "$DISK"
sgdisk -o "$DISK"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$DISK"
sgdisk -n 2:0:+40G  -t 2:8300 -c 2:"Root" "$DISK"
sgdisk -n 3:0:+4G   -t 3:8200 -c 3:"Swap" "$DISK"
sgdisk -n 4:0:0     -t 4:8300 -c 4:"Home" "$DISK"

sleep 2

echo "Formating..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "${DISK}4"
mkswap "${DISK}3"

mount "${DISK}2" /mnt
mkdir -p /mnt/{boot,home}
mount "${DISK}1" /mnt/boot
mount "${DISK}4" /mnt/home
swapon "${DISK}3"

echo "Installing base system and some packages..."
pacstrap -K /mnt base linux linux-firmware \
    sudo nano git curl wget xdg-user-dirs \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    bash-completion man-db man-pages \
    networkmanager base-devel

genfstab -U /mnt >> /mnt/etc/fstab

echo "Cooking with chroot..."

arch-chroot /mnt /bin/bash <<EOF
echo "$HOSTNAME" > /etc/hostname
ln -sf /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime
hwclock --systohc

echo "es_AR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_AR.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

echo "Installing GRUB..."
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

echo "Instalación finalizada con éxito. Podés reiniciar el sistema."
