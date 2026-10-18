# Desktop theming (applied 2026-10-18)

What was added on top of the working niri + DankMaterialShell install so the
desktop and terminal are actually usable and good-looking out of the box.

## Packages added

| Package | Version | Why |
| --- | --- | --- |
| `ghostty` (+ `ghostty-terminfo`) | 1.1.3 | Terminal; DMS knows how to theme it |
| `zsh` | 5.9.2 | Login shell for `animated` |
| `starship` | 1.26.0 | Prompt |
| `zsh-autosuggestions` | 0.7.0 | Suggestions from history |
| `zsh-syntax-highlighting` | 0.8.0 | Live command highlighting |
| `eza`, `bat`, `fastfetch` | 0.23.5 / 0.26.1 / 2.69.0 | `ls`/`cat` replacements + login banner |
| `zoxide`, `fzf`, `fd`, `ripgrep`, `jq` | — | Shell quality-of-life |
| `xdg-desktop-portal-wlr` | 0.8.4 | ScreenCast portal backend under niri |

`polkitd` was **enabled** (it was installed but not running) and
`power-profiles-daemon` enabled too. `power-profiles-daemon` and
`cups-pk-helper` turned out to already be installed.

## Files written on the target

| Path | Contents |
| --- | --- |
| `~/.config/niri/config.kdl` | Rewritten by `dms setup headless`, then: added the missing `include "dms/windowrules.kdl"` and `spawn-at-startup "pipewire"` / `"wireplumber"` |
| `~/.config/niri/dms/*.kdl` | DMS-managed: `colors layout alttab binds outputs cursor input windowrules` |
| `~/.config/ghostty/config` | DMS-deployed, plus `font-family = "FiraCode Nerd Font"` |
| `~/.config/ghostty/themes/dankcolors` | Matugen-generated palette (background `#101418`) |
| `~/.config/starship.toml` | Minimal prompt config |
| `~/.zshrc` | History, autosuggestions, syntax highlighting, zoxide, starship, `eza`/`bat` aliases, `fastfetch` banner |
| `~/.local/state/DankMaterialShell/session.json` | Wallpaper: `wallpaperPath` (`hidden-temple.jpg`), `wallpaperFillMode: PreserveAspectCrop` |
| `/etc/xdg/xdg-desktop-portal/niri-portals.conf` | `default=gnome;gtk`, ScreenCast/Screenshot → `wlr` |

`animated`'s shell was changed to `/bin/zsh` via `usermod -s`.

DMS's niri config sets `environment { TERMINAL "ghostty" ... }`, which is what
the DMS "system updates" widget uses.

## Wallpapers

All eleven are in `~/Pictures/Wallpapers/` (downloaded with `dms dl`, which
pulled them over the QEMU user-network from an HTTP server on the Windows host):

| File | Resolution | What it is |
| --- | --- | --- |
| `hidden-temple.jpg` | 3840×1809 | **the default** — "The Hidden Temple": an Asian-style temple complex in a dark forest, red-walled buildings with curved rooftops around a courtyard, one huge golden/orange tree lit in the middle |
| `sunset-over-the-mountains.jpg` | 736×414 | "Sunset Over the Mountains": countryside at sunset, lake, winding road, power poles, birds, pink/purple/orange sky |
| `bliss-xp.png` | 1080×607 | XP-"Bliss" style (blue sky / green field) |
| `desktop.jpg` | 1536×864 | |
| `gnome-dark.png` | 3840×2160 | |
| `msi-meg-godlike.jpg` | 3840×2160 (2.0 MB) | |
| `msi-meg-ace.jpg` | 3840×2160 | |
| `msi-mag.jpg`, `msi-mpg.jpg`, `msi-pro.jpg`, `msi-msi.png` | 3840×2160 | |

The two named ones came from `~/Downloads` with a description note (the user's
`ahhhh!!!.txt`), staged to the VM as `hidden-temple.jpg` and
`sunset-over-the-mountains.jpg`.

Two of the candidates are below display resolution and will be upscaled to
2560×1440: `bliss-xp.png` (1080×607, ~2.4×) and `sunset-over-the-mountains.jpg`
(736×414, ~3.5×). The Hidden Temple is near-4K, so it stays sharp. matugen
regenerates the entire colour scheme from whichever image is selected.

## Verifying after first login

```sh
niri validate          # "config is valid"
dms doctor             # optional-feature report
dms keybinds list      # what the keybinds actually are
sudo dms-greeter sync  # mirror this theme onto the login screen
```

`dms-greeter sync` needs to run as the logged-in user (it calls `sudo`
internally); the previous run happened as root, so a fresh sync from `animated`
is what links the login screen to this theme. The group membership for that is
already in place (`animated` is in `_greeter`).

## Notes / caveats

- `xbps-pkgdb -a` reports `hash mismatch for /etc/sv/greetd/run` and
  `/etc/pam.d/greetd` — both are expected, `dms-greeter enable`/`sync` own them.
- `quickshell-git` does not exist as a package here; `dms doctor`'s suggestion to
  use it cannot be followed on Void, so upstream `quickshell` 0.3.2 stays.
- `settings.json`, `clsettings.json`, `plugin_settings.json` and
  `dms-colors.json` do not exist yet; DMS writes them on first run.
