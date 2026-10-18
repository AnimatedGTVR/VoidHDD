#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
R() { chroot $M "$@"; }

echo "=== dry run: quickshell-git / power-profiles-daemon / cups-pk-helper ==="
R xbps-install -n quickshell-git 2>&1 | tail -15
echo "--- power-profiles-daemon ---"
R xbps-install -n power-profiles-daemon 2>&1 | tail -8
echo "--- cups-pk-helper ---"
R xbps-install -n cups-pk-helper 2>&1 | tail -8
echo "--- xdg-desktop-portal-wlr (niri screencast portal) ---"
R xbps-install -n xdg-desktop-portal-wlr 2>&1 | tail -8

echo "=== enable polkitd ==="
if [ ! -e $M/etc/runit/runsvdir/default/polkitd ]; then
  ln -s /etc/sv/polkitd $M/etc/runit/runsvdir/default/polkitd
fi
ls -l $M/etc/runit/runsvdir/default/ | sed 's/.*default\///'

echo PHASE1D_DONE
