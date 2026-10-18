#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
R() { chroot $M "$@"; }
A() { chroot $M su -l animated -c "$1"; }

echo "=== dry-run install (which of these actually exist) ==="
R xbps-install -n ghostty zsh starship eza bat fastfetch zsh-autosuggestions zsh-syntax-highlighting zoxide fzf fd ripgrep jq yazi 2>&1 | tail -25
echo "=== dms setup headless --help ==="
A "dms setup headless --help" 2>/dev/null | tail -25
echo "=== dms setup binds --help ==="
A "dms setup binds --help" 2>/dev/null | tail -15
echo "=== dms dl --help ==="
A "dms dl --help" 2>/dev/null | tail -20
echo "=== can the VM reach the Windows host? ==="
A "dms dl -o /tmp/t.png http://10.0.2.2:8000/bliss-xp.png" 2>&1 | tail -3
ls -l /mnt/tmp/t.png /tmp/t.png 2>&1
echo "=== current niri config (to be replaced by dms setup) ==="
wc -l $M/home/animated/.config/niri/config.kdl
echo PHASE0_DONE
