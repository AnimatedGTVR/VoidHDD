#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
A() { chroot $M su -l animated -c "$1"; }
echo "=== niri config validation ==="
A "niri validate" 2>&1 | tail -20
echo "rc=$?"
echo "=== package db check ==="
chroot $M xbps-pkgdb -a 2>&1 | grep -viE 'files check OK' | tail -10
echo "=== session.json ==="
cat $M/home/animated/.local/state/DankMaterialShell/session.json
echo VERIFY_DONE
