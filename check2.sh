#!/bin/sh
set -eu
mkdir -p /mnt
mountpoint -q /mnt || mount /dev/vda2 /mnt

echo "=== VERSIONS ==="
for p in linux6.12 linux-lts linux-firmware-amd mesa base-system xbps; do
    v=$(chroot /mnt xbps-query -p pkgver "$p" 2>/dev/null || echo "NOT_INSTALLED")
    echo "$p: $v"
done

echo "=== INSTALLED PACKAGES ==="
chroot /mnt xbps-query -l 2>/dev/null | awk '{print $2}' | sed 's/-[0-9].*//' | sort | tr '\n' ' '
echo
chroot /mnt xbps-query -l 2>/dev/null | wc -l

echo "=== REPO CONFIG ==="
ls /mnt/etc/xbps.d/ 2>/dev/null || echo none
cat /mnt/etc/xbps.d/*.conf 2>/dev/null || true

echo "=== SERVICES ENABLED ==="
ls -1 /mnt/etc/runit/runsvdir/default/ 2>/dev/null | tr '\n' ' ' || echo none

echo "=== FSTAB ==="
cat /mnt/etc/fstab

echo "=== DISK FREE ==="
df -h /mnt | tail -1

echo CHECK2_DONE
