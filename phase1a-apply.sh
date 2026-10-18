#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
R() { chroot $M "$@"; }
A() { chroot $M su -l animated -c "$1"; }

echo "=== wallpaper-related keys inside the binaries ==="
strings $M/usr/sbin/dms 2>/dev/null | grep -iE 'wallpaper' | sort -u | head -25
echo "--- dms-greeter ---"
strings $M/usr/sbin/dms-greeter 2>/dev/null | grep -iE 'wallpaper' | sort -u | head -15

echo "=== installing ghostty/zsh/starship/tools ==="
R xbps-install -Sy ghostty zsh starship eza bat fastfetch zsh-autosuggestions zsh-syntax-highlighting zoxide fzf fd ripgrep jq 2>&1 | tail -8

echo "=== dms setup headless ==="
A "dms setup headless --compositor niri --terminal ghostty --no-systemd --force" 2>&1 | tail -30

echo "=== resulting niri config ==="
ls -la $M/home/animated/.config/niri/ 2>&1 | tail -8
grep -nE 'spawn-at-startup|^environment|DMS_|TERMINAL' $M/home/animated/.config/niri/config.kdl 2>/dev/null | head -20
echo "=== resulting ghostty config ==="
ls -la $M/home/animated/.config/ghostty/ 2>&1 | tail -8
head -40 $M/home/animated/.config/ghostty/config 2>/dev/null

echo "=== wallpapers ==="
R mkdir -p /home/animated/Pictures/Wallpapers
R chown -R animated:animated /home/animated/Pictures
for f in bliss-xp.png desktop.jpg gnome-dark.png msi-msi.png msi-mag.jpg msi-meg-ace.jpg msi-meg-godlike.jpg msi-mpg.jpg msi-pro.jpg; do
    A "dms dl -o /home/animated/Pictures/Wallpapers/$f http://10.0.2.2:8000/$f" >/dev/null 2>&1
done
ls -l $M/home/animated/Pictures/Wallpapers/
echo PHASE1A_DONE
