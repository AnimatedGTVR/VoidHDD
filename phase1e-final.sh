#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
R() { chroot $M "$@"; }

echo "=== install xdg-desktop-portal-wlr ==="
R xbps-install -Sy xdg-desktop-portal-wlr 2>&1 | tail -5

echo "=== portal config for niri ==="
mkdir -p $M/etc/xdg/xdg-desktop-portal
cat > $M/etc/xdg/xdg-desktop-portal/niri-portals.conf <<'PEOF'
[preferred]
default=gnome;gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.ScreenCast.PipeWire=wlr
PEOF
cat $M/etc/xdg/xdg-desktop-portal/niri-portals.conf

echo "=== power-profiles-daemon service? ==="
ls -d $M/etc/sv/power-profiles-daemon 2>&1
if [ -d $M/etc/sv/power-profiles-daemon ] && [ ! -e $M/etc/runit/runsvdir/default/power-profiles-daemon ]; then
  ln -s /etc/sv/power-profiles-daemon $M/etc/runit/runsvdir/default/power-profiles-daemon
fi

echo "=== greetd session for the logged-in user ==="
cat $M/etc/greetd/config.toml

echo "=== final enabled services ==="
ls $M/etc/runit/runsvdir/default/

echo "=== final desktop packages ==="
R xbps-query -l 2>/dev/null | grep -iE 'ghostty|^ii zsh|starship|eza|bat-|fastfetch|niri|dms|quickshell|pipewire|wireplumber|matugen|xdg-desktop-portal' | awk '{print $2}'

echo "=== animated home tree ==="
find $M/home/animated -maxdepth 3 \( -name '*.kdl' -o -name 'config' -o -name '*.toml' -o -name '*.json' -o -name '.zshrc' \) 2>/dev/null | sed 's|/mnt||'
echo "=== wallpaper dir ==="
ls -l $M/home/animated/Pictures/Wallpapers/ | tail -n +2
echo PHASE1E_DONE
