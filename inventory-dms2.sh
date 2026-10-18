#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do
    mountpoint -q $M/$d || mount --rbind /$d $M/$d
done
R() { chroot $M "$@"; }

echo "=== dms commands (full) ==="
R su -l animated -c "dms --help" 2>/dev/null | sed -n '/Available Commands/,$p'
echo "=== dms config/theme/wallpaper help ==="
for c in config theme wallpaper matugen color; do
    echo "--- dms $c ---"
    R su -l animated -c "dms $c --help" 2>/dev/null | head -18
done
echo "=== wallpaper-related strings in the binary ==="
strings $M/usr/sbin/dms 2>/dev/null | grep -iE '^wallpaper|wallpaper[A-Za-z]*\.json|wallpaperPath|wallpaperDir' | sort -u | head -20
echo "=== dms package json/qml files ==="
R xbps-query -f dms 2>/dev/null | sed "s|^$M||" | grep -iE '\.json|\.qml|share/dank|settings' | head -20
echo "=== font families of interest ==="
R fc-list : family 2>/dev/null | tr ',' '\n' | sort -u | grep -iE 'inter|jetbrains|fira|noto sans$|noto sans mono|cascadia|hack|source code|iosevka|ubuntu|dejavu' | head -20
echo "=== terminal/related packages installed ==="
R sh -c 'xbps-query -l | grep -iE "terminal|foot|kitty|ghostty|alacritty|zsh|fish|starship|swaybg|swww|hyprpaper|mpvpaper|imv|bat|eza|fzf|tmux"' | head -20
echo "=== available in repos ==="
R sh -c 'for p in foot ghostty kitty alacritty zsh fish starship swaybg mpvpaper imv bat eza tmux fastfetch; do printf "%-12s %s\n" "$p" "$(xbps-query -R -s "^$p-" 2>/dev/null | head -1)"; done'
echo INV3_DONE
