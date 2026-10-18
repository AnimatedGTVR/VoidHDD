#!/bin/sh
# The ESP backup carries the old Omarchy/Limine bootloader, whose default
# entry targets a LUKS/btrfs root that no longer exists. Keep a backup copy,
# then install Void GRUB as the standard EFI removable fallback so plain
# firmware boots land on Void's GRUB (EFI/BOOT/BOOTX64.EFI).
set -eu
mkdir -p /mnt
mountpoint -q /mnt || mount /dev/vda2 /mnt
mkdir -p /mnt/boot/efi
mountpoint -q /mnt/boot/efi || mount /dev/vda1 /mnt/boot/efi
mountpoint -q /mnt/dev || { mount --rbind /dev /mnt/dev; mount --make-rslave /mnt/dev; }
mountpoint -q /mnt/proc || mount -t proc proc /mnt/proc
mountpoint -q /mnt/sys || { mount --rbind /sys /mnt/sys; mount --make-rslave /mnt/sys; }

if [ -f /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI ] && [ ! -f /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI.limine-bak ]; then
    cp /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI.limine-bak
fi

chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void --removable --no-nvram
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
test -s /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI
ls -la /mnt/boot/efi/EFI/BOOT/
echo FALLBACK_FIXED
