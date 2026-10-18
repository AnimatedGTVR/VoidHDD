#!/bin/sh
M=/mnt
mountpoint -q $M || mount /dev/vda2 $M
for d in dev proc sys; do mountpoint -q $M/$d || mount --rbind /$d $M/$d; done
H=$M/home/animated
R() { chroot $M "$@"; }

echo "=== plugin file locations ==="
find $M/usr/share -name 'zsh-autosuggestions.zsh' -o -name 'zsh-syntax-highlighting.zsh' 2>/dev/null
echo "--- versions ---"
R ghostty --version 2>&1 | head -1
R zsh --version
R starship --version | head -1

echo "=== full generated niri config ==="
cat $H/.config/niri/config.kdl

echo "=== write session.json (wallpaper) ==="
mkdir -p $H/.local/state/DankMaterialShell
cat > $H/.local/state/DankMaterialShell/session.json <<'JSONEOF'
{
  "wallpaperPath": "/home/animated/Pictures/Wallpapers/bliss-xp.png",
  "wallpaperFillMode": "PreserveAspectCrop",
  "monitorWallpapers": {}
}
JSONEOF

echo "=== zsh ==="
R usermod -s /bin/zsh animated
cat > $H/.zshrc <<'ZSHEOF'
# Void + DankMaterialShell zsh setup
autoload -Uz compinit && compinit

HISTFILE=~/.zsh_history
HISTSIZE=20000
SAVEHIST=20000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY INC_APPEND_HISTORY

for f in /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
         /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [ -r "$f" ] && source "$f" && break
done
for f in /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "$f" ] && source "$f" && break
done

command -v zoxide  >/dev/null && eval "$(zoxide init zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias cat='bat'
alias ff='fastfetch'
alias gs='git status -sb'

if [ -n "$PS1" ] && command -v fastfetch >/dev/null; then fastfetch; fi
ZSHEOF

cat > $H/.config/starship.toml <<'STAREOF'
add_newline = true
format = "$directory$git_branch$git_status$character"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[directory]
truncation_length = 4
truncate_to_repo = true
style = "bold cyan"

[git_branch]
style = "bold purple"

[git_status]
style = "bold yellow"
STAREOF

echo "=== ghostty font ==="
if ! grep -q '^font-family' $H/.config/ghostty/config; then
  cat >> $H/.config/ghostty/config <<'GTEOF'

# Fonts (Nerd Font installed on this system)
font-family = "FiraCode Nerd Font"
font-family-bold = "FiraCode Nerd Font"
font-family-italic = "FiraCode Nerd Font"
font-family-bold-italic = "FiraCode Nerd Font"
GTEOF
fi
grep -n '^font-family' $H/.config/ghostty/config
echo "--- ghostty theme file ---"
ls -l $H/.config/ghostty/themes/
echo "--- dankcolors (first 15 lines) ---"
head -15 $H/.config/ghostty/themes/dankcolors

echo "=== ownership ==="
chown -R 1000:1000 $H/.zshrc $H/.config $H/.local $H/Pictures
ls -l $H/.zshrc $H/.local/state/DankMaterialShell/session.json
R getent passwd animated
echo PHASE1B_DONE
