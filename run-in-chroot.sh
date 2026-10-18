#!/bin/sh
#
# run-in-chroot.sh — launch install-niri-dms.sh inside the offline Void root.
# Used because the desktop has no login we can drive from here; this performs
# the identical install against /dev/vda2 and can be re-run any time.
#
set -u
LOG=/mnt/root/niri-dms-install.log

mountpoint -q /mnt || mount /dev/vda2 /mnt
mkdir -p /mnt/boot/efi
mountpoint -q /mnt/boot/efi || mount /dev/vda1 /mnt/boot/efi
for d in dev proc sys run; do
    mkdir -p "/mnt/$d"
    mountpoint -q "/mnt/$d" || mount --rbind "/$d" "/mnt/$d"
done
mount --make-rslave /mnt/dev
cp -L /etc/resolv.conf /mnt/etc/resolv.conf

cp /tmp/install-niri-dms.sh /mnt/root/install-niri-dms.sh
chmod 0755 /mnt/root/install-niri-dms.sh

# Pre-write the DankLinux repos and import their signing key non-interactively,
# so the script's own xbps calls never block waiting for a y/n on a pipe.
printf 'repository=%s\n' "https://void.danklinux.com/dms/current" > /mnt/etc/xbps.d/dms.conf
printf 'repository=%s\n' "https://void.danklinux.com/danklinux/current" > /mnt/etc/xbps.d/danklinux.conf
echo "--- pre-sync (importing DankLinux key) ---"
chroot /mnt sh -c 'yes | xbps-install -S' > /mnt/root/pre-sync.log 2>&1 || true
grep -iE 'fingerprint|import|key|error' /mnt/root/pre-sync.log | head -20 || true

if pgrep -f install-niri-dms.sh >/dev/null 2>&1; then
    echo "ALREADY_RUNNING"
else
    rm -f "$LOG"
    chroot /mnt sh -c 'nohup sh /root/install-niri-dms.sh > /root/niri-dms-install.log 2>&1 &'
    sleep 3
    echo LAUNCHED
fi
