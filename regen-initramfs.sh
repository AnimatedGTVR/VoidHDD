#!/bin/sh
# TCG panics this kernel in setup_IO_APIC right when the early AMD
# microcode blob from linux-firmware-amd is present. Rebuild the initramfs
# without early microcode (harmless; hardware applies microcode via BIOS).
set -eu
mkdir -p /mnt
mountpoint -q /mnt || mount /dev/vda2 /mnt
mkdir -p /mnt/boot/efi
mountpoint -q /mnt/boot/efi || mount /dev/vda1 /mnt/boot/efi
mountpoint -q /mnt/dev || { mount --rbind /dev /mnt/dev; mount --make-rslave /mnt/dev; }
mountpoint -q /mnt/proc || mount -t proc proc /mnt/proc
mountpoint -q /mnt/sys || { mount --rbind /sys /mnt/sys; mount --make-rslave /mnt/sys; }
cp /mnt/boot/initramfs-6.12.11_1.img /mnt/boot/initramfs-6.12.11_1.img.bak
chroot /mnt dracut --force --no-early-microcode --kver 6.12.11_1 /boot/initramfs-6.12.11_1.img
ls -la /mnt/boot/initramfs-6.12.11_1.img
echo REGEN_INITRAMFS_DONE
