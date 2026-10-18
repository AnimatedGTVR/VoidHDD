#!/bin/sh
# Revert the temporary serial-console debug param added for the QEMU test.
set -eu
mkdir -p /mnt
mountpoint -q /mnt || mount /dev/vda2 /mnt
mkdir -p /mnt/boot/efi
mountpoint -q /mnt/boot/efi || mount /dev/vda1 /mnt/boot/efi
mountpoint -q /mnt/dev || { mount --rbind /dev /mnt/dev; mount --make-rslave /mnt/dev; }
mountpoint -q /mnt/proc || mount -t proc proc /mnt/proc
mountpoint -q /mnt/sys || { mount --rbind /sys /mnt/sys; mount --make-rslave /mnt/sys; }

sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4"/' /mnt/etc/default/grub
grep '^GRUB_CMDLINE_LINUX_DEFAULT' /mnt/etc/default/grub
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
grep -c 'console=ttyS0' /mnt/boot/grub/grub.cfg && echo 'STILL_PRESENT' || echo 'CONSOLE_REVERTED'
sync
echo REVERT_DONE
