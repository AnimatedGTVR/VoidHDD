#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
H=$M/home/animated
R() { chroot $M "$@"; }
A() { chroot $M su -l animated -c "$1"; }

echo "=== wayland session entry ==="
ls $M/usr/share/wayland-sessions/ 2>/dev/null
cat $M/usr/share/wayland-sessions/*.desktop 2>/dev/null
echo "--- niri-session present? ---"
ls -l $M/usr/bin/niri-session 2>&1

echo "=== portal / audio / polkit packages ==="
R xbps-query -l 2>/dev/null | grep -iE 'xdg-desktop-portal|polkit|pipewire|wireplumber|seatd|greetd|elogind' | awk '{print $2}'

echo "=== relevant runit services on the installed system ==="
ls $M/etc/sv/ 2>/dev/null | grep -iE 'pipewire|wireplumber|polkit|seatd|dbus|elogind|greetd'
echo "--- enabled ---"
ls $M/etc/runit/runsvdir/default/ 2>/dev/null

echo "=== xdg autostart entries ==="
ls $M/etc/xdg/autostart/ 2>/dev/null

echo "=== dms doctor (as animated) ==="
A "dms doctor" 2>&1 | tail -40

echo "=== niri config: include windowrules + start audio ==="
if ! grep -q 'dms/windowrules.kdl' $H/.config/niri/config.kdl; then
  printf 'include optional=true "dms/windowrules.kdl"\n' >> $H/.config/niri/config.kdl
fi
if ! grep -q 'spawn-at-startup "pipewire"' $H/.config/niri/config.kdl; then
  printf 'spawn-at-startup "pipewire"\nspawn-at-startup "wireplumber"\n' >> $H/.config/niri/config.kdl
fi
tail -12 $H/.config/niri/config.kdl
chown 1000:1000 $H/.config/niri/config.kdl
echo PHASE1C_DONE
