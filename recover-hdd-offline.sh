#!/bin/sh
# Run only in the Void live environment with:
#   /dev/vda = WDC 2 TB target disk
#   /dev/vdb = the 2 GiB esp-backup.img (read-only)
set -eu

expected_sectors=3907029168
expected_backup_sha=ed547c1775b35eacf010558e7949fd55cb1795760f9fa99b84d83a846398a6bc

[ "$(blockdev --getsz /dev/vda)" = "$expected_sectors" ] || {
    echo 'REFUSING: /dev/vda is not the expected 2 TB disk.' >&2
    exit 1
}
[ "$(blockdev --getsize64 /dev/vdb)" = 2147483648 ] || {
    echo 'REFUSING: /dev/vdb is not the 2 GiB EFI backup.' >&2
    exit 1
}
printf '%s  /dev/vdb\n' "$expected_backup_sha" | sha256sum -c -

echo 'This restores the original GPT and EFI backup, then repairs the Void filesystem.'
echo 'Type RESTORE-WD20EZBX to continue:'
read answer
[ "$answer" = 'RESTORE-WD20EZBX' ] || exit 1

umount /dev/vda1 /dev/vda2 2>/dev/null || true
swapoff /dev/vda1 /dev/vda2 2>/dev/null || true

# Exact original geometry recorded before the damage.
sfdisk --wipe always /dev/vda <<'EOF'
label: gpt
unit: sectors

/dev/vda1 : start=2048, size=4194304, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
/dev/vda2 : start=4196352, size=3902832640, type=4F68BCE3-E8CD-4DB1-96E7-FBCaf984B709, name="Void root"
EOF
if command -v partprobe >/dev/null 2>&1; then
    partprobe /dev/vda
else
    blockdev --rereadpt /dev/vda || true
fi
udevadm settle

# Restore the byte-for-byte EFI partition backup made before any repair work.
dd if=/dev/vdb of=/dev/vda1 bs=8M iflag=fullblock conv=fsync
fsck.vfat -a /dev/vda1

# Repair metadata damage in the existing Void root.
e2fsck -f -y /dev/vda2
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

# Requested system identity. Passwords are deliberately left for the final
# interactive step and are never stored in a script or log.
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
echo 'Next: run finish-void-passwords.sh interactively.'
