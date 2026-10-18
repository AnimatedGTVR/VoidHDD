#!/bin/sh
set -eu
mount /dev/vda2 /mnt
mount /dev/vda1 /mnt/boot/efi
echo '=== Existing boot configuration ==='
ls /mnt/boot/efi/EFI
cat /mnt/etc/fstab
test -s /mnt/boot/vmlinuz-6.12.11_1
test -s /mnt/boot/initramfs-6.12.11_1.img
find /mnt/boot/efi/EFI -type f -exec sha256sum '{}' + > /tmp/efi-before.sha256
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount -t proc proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
echo '=== Repair bootloader ==='
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void --no-nvram
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
echo '=== Verify pre-existing EFI files unchanged ==='
sha256sum -c /tmp/efi-before.sha256
echo '=== Verify generated boot files ==='
test -s /mnt/boot/efi/EFI/Void/grubx64.efi
test -s /mnt/boot/grub/grub.cfg
grep -E 'menuentry |linux |initrd ' /mnt/boot/grub/grub.cfg
echo '=== Root account status (no password hashes) ==='
chroot /mnt passwd -S root
echo '=== Set VM firmware entry ==='
if [ -d /sys/firmware/efi ]; then
    efibootmgr -c -d /dev/vda -p 1 -L Void -l '\EFI\Void\grubx64.efi'
fi
sync
echo REPAIR_OK
