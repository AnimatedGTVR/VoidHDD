#!/bin/sh
# Continued after e2fsck completed (its exit-1 "errors corrected" tripped
# set -e in recover-hdd-offline-v2.sh). Filesystem is repaired; finish here.
set -eu
mkdir -p /mnt
mount /dev/vda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount -t proc proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys

chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void --no-nvram
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
test -s /mnt/boot/efi/EFI/Void/grubx64.efi
test -s /mnt/boot/grub/grub.cfg

printf 'void\n' > /mnt/etc/hostname
ln -sfn /usr/share/zoneinfo/America/New_York /mnt/etc/localtime
if ! chroot /mnt id animated >/dev/null 2>&1; then
    chroot /mnt useradd -m -s /bin/bash animated
fi
chroot /mnt usermod -aG wheel,audio,video,network animated
if ! chroot /mnt xbps-pkgdb -a; then
    touch /mnt/root/XBPS-REPAIR-REQUIRED
    echo 'WARNING: XBPS reported package integrity issues; marker created.'
fi
sync
echo 'RECOVERY_COMPLETE_PASSWORDS_PENDING'
