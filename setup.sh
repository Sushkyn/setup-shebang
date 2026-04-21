#!/bin/bash

KEYMAP="us"
loadkeys $KEYMAP
REGION_CITY="Europe/Moscow"
HOST="localhost"
USERNAME="shebang"
ROOT_PASSWORD=""
pass1=""
pass2=""
DISK=""

if grep -q "GenuineIntel" /proc/cpuinfo; then
    cpu="intel-ucode"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    cpu="amd-ucode"
fi

password() {
  stty -echo
  until [ "$pass1" = "$pass2" ] && [ "$pass1" ] && [ "$pass2" ]; do
    printf "\n%s\n" "$1" >&2 && read -p $"> " pass1
    printf "\nRe-type %s\n" "$1" >&2 && read -p $"> " pass2
  done
  stty echo
  echo -e "$pass2"
}

# Pacman
echo -e '# Default mirrors
Server = https://mirrors.rit.edu/artixlinux/$repo/os/$arch
Server = https://mirrors.dotsrc.org/artix-linux/repos/$repo/os/$arch' >/etc/pacman.d/mirrorlist
sed -i -e '/^HoldPkg/a XferCommand = /sbin/curl -fSL --proto '\''=https'\'' --tlsv1.3 --progress-bar -o %o %u' /etc/pacman.conf
sed -i -e 's/^SigLevel.*/SigLevel = Required DatabaseOptional TrustedOnly/g' /etc/pacman.conf
sed -i -e s"/\#CleanMethod.*/CleanMethod = KeepCurrent/"g /etc/pacman.conf

# Dependencies
command -v parted >/dev/null 2>&1 || pacman -Sy --needed --noconfirm --disable-download-timeout parted

# Root
[ ! "$ROOT_PASSWORD" ] && ROOT_PASSWORD=$(password "Password for superuser (will use same for root)")

# Choose disk
until [ -e "$DISK" ]; do
  clear
  sfdisk -l | grep -E "/dev/"
  echo ""
  echo -e "WARNING: The selected disk will be rewritten."
  echo -e "Disk to install (e.g. /dev/[drive letter])" && read -p $"> " DISK
done

case "$DISK" in
  *"nvme"*)
    PART1="$DISK"p1
    PART2="$DISK"p2
    ;;
  *)
    PART1="$DISK"1
    PART2="$DISK"2
    ;;
esac

ROOT_PART=$PART2

# Encrypt
CRYPTPASS=$(password "Password for encryption (must at least 6 characters)")

# Partition disk
clear
swapoff -a
umount -AR /mnt*
cryptsetup close /dev/mapper/root

dd if=/dev/zero of=$DISK bs=2M status=progress && sync -f || sync -f
dd if=/dev/urandom of=$DISK bs=2M status=progress && sync -f || sync -f

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$DISK" mkpart primary ext4 512MiB 100%
parted -s "$DISK" set 1 boot on

# Encrypt drive
echo -ne "$CRYPTPASS" | cryptsetup -q luksFormat --pbkdf=pbkdf2 "$ROOT_PART"
echo -ne "$CRYPTPASS" | cryptsetup open "$ROOT_PART" root

ROOT_PART="/dev/mapper/root"

# Format and mount partitions
mkfs.fat -F 32 "$PART1"
fatlabel "$PART1" ESP
mkfs.ext4 -L root -F -O ^quota,^has_journal,^metadata_csum,^ext_attr,^extra_isize,uninit_bg,fast_commit -b2048 -m1 "$ROOT_PART"
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi
# Create swapfile
mkdir /mnt/swap
fallocate -l  12G /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Install base system and kernel
clear
echo -e 'Done with configuration. Installing...'

basestrap /mnt base runit elogind-runit efibootmgr dbus-runit dhcpcd-runit grub $cpu wpa_supplicant-runit cryptsetup-runit

basestrap /mnt linux-hardened linux-hardened-headers linux-firmware mkinitcpio

fstabgen -U /mnt >/mnt/etc/fstab

# Chroot
mkdir -p /mnt/root/shebang-linux
cp /root/shebang-linux/deploy.sh /mnt/root/shebang-linux/
chmod +x /mnt/root/shebang-linux/deploy.sh
(PART2="$PART2" ROOT_PASSWORD="$ROOT_PASSWORD" REGION_CITY="$REGION_CITY" HOST="$HOST" USERNAME="$USERNAME" KEYMAP="$KEYMAP" artix-chroot /mnt /bin/bash -c 'bash /root/shebang-linux/deploy.sh; exit')

# Perform finish
swapoff -a
umount -AR /mnt*
cryptsetup close "$ROOT_PART"
