#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
R() { chroot $M "$@"; }
A() { chroot $M su -l animated -c "$1"; }

echo "=== dms setup --help ==="
A "dms setup --help" 2>/dev/null
echo "=== dms keybinds --help ==="
A "dms keybinds --help" 2>/dev/null | head -20
echo "=== dms ipc --help ==="
A "dms ipc --help" 2>/dev/null | head -20
echo "=== root DMS config (greeter sync made this) ==="
ls -la $M/root/.config/DankMaterialShell/ 2>&1
echo "--- settings.json (keys only) ---"
grep -oE '"[a-zA-Z0-9_]+"\s*:' $M/root/.config/DankMaterialShell/settings.json 2>/dev/null | tr -d '":' | tr '\n' ' '
echo
echo "--- size ---"
wc -c $M/root/.config/DankMaterialShell/settings.json 2>/dev/null
echo "=== package availability ==="
R sh -c 'for p in ghostty zsh starship eza bat fastfetch zsh-autosuggestions zsh-syntax-highlighting zoxide fzf fd ripgrep jq yazi; do printf "%-26s %s\n" "$p" "$(xbps-query -R -s "^$p-" 2>/dev/null | head -1)"; done'
echo "=== does ghostty/anything have a matugen template in dms ==="
A "dms matugen check" 2>/dev/null | head -30
echo "=== live net from VM to host ==="
R sh -c 'command -v curl wget busybox; busybox wget -q -O- http://10.0.2.2:8000/ 2>&1 | head -3'
echo INV4_DONE
