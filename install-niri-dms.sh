#!/bin/sh
#
# install-niri-dms.sh — stage niri + DankMaterialShell on this Void Linux install.
#
# Not run yet: this is the reviewed plan, kept in the repo so it can be read,
# diffed and re-run idempotently.
#
# Run it on the *real* booted system (not from the live ISO), as root:
#
#     sudo sh install-niri-dms.sh 2>&1 | tee ~/niri-dms-install.log
#
# What it does, in order:
#   1. preflight: root, xbps, network, disk space
#   2. back up /etc/xbps.d and any existing niri config
#   3. point xbps at an official Void mirror (replaces mirrors.summithq.com)
#   4. add the DankLinux xbps repos (dms, danklinux)
#   5. update the whole system: kernel 6.18 + Mesa 26.2.5 + firmware
#      (this is the step that makes the RX 9060 XT / RDNA4 work at all)
#   6. install the Wayland/DMS/niri stack
#   7. audio: PipeWire + WirePlumber + pulse + ALSA shim
#   8. services: dbus, elogind (seat), optional NetworkManager
#   9. greeter: dms-greeter enable + sync (sets up greetd for runit)
#  10. user config: dms setup (niri keybinds + autostart), flatpak, verify
#
# Re-running is safe: every step checks before it acts.
#
set -u

# --- knobs ---------------------------------------------------------------
VOID_MIRROR="https://repo-default.voidlinux.org/current"
DMS_REPO="https://void.danklinux.com/dms/current"
DANK_REPO="https://void.danklinux.com/danklinux/current"
DMS_PKG="dms"                 # stable; use dms-git for the development build
HOST_USER="animated"          # the desktop user
USE_NETWORKMANAGER="yes"      # "yes" if you want the DMS network widget to work
BACKUP_DIR="/root/niri-dms-backup-$(date +%Y%m%d-%H%M%S)"

OK="[ ok ]"; WARN="[warn]"; INFO="[info]"
die() { echo "${WARN} $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
svc_enabled() { [ -L "/var/service/$1" ]; }
svc_enable() { [ -L "/var/service/$1" ] || ln -sf "/etc/sv/$1" /var/service/; }
svc_disable() { [ -L "/var/service/$1" ] && rm -f "/var/service/$1"; }

# --- 1. preflight --------------------------------------------------------
echo "== preflight =="
[ "$(id -u)" = 0 ] || die "run me as root (sudo sh $0)"
have xbps-install || die "xbps-install not found — is this actually Void?"
[ -n "$(ls -A /etc/xbps.d 2>/dev/null)" ] || die "/etc/xbps.d is empty — xbps is not configured"
id "$HOST_USER" >/dev/null 2>&1 || die "no user '$HOST_USER' (set HOST_USER= to your login)"

avail_kb=$(df -Pk / | awk 'NR==2 {print $4}')
[ "$avail_kb" -ge 15000000 ] || die "need ~15G free on / for the update, have $((avail_kb/1024))M"

echo "$INFO current kernel(s):"; ls -1 /boot/vmlinuz-* 2>/dev/null | sed 's/^/       /'
echo "$INFO checking network..."
xbps-install -S >/dev/null 2>&1 || die "cannot reach a repository — fix networking first"
echo "$OK preflight passed, $(df -h / | awk 'NR==2 {print $4}') free on /"

# --- 2. backup -----------------------------------------------------------
echo "== backup =="
mkdir -p "$BACKUP_DIR"
cp -a /etc/xbps.d "$BACKUP_DIR/xbps.d" 2>/dev/null || true
cp -a /etc/default/grub "$BACKUP_DIR/grub.default" 2>/dev/null || true
cp -a "/home/$HOST_USER/.config/niri" "$BACKUP_DIR/niri" 2>/dev/null || true
[ -f /etc/greetd/config.toml ] && cp -a /etc/greetd/config.toml "$BACKUP_DIR/greetd-config.toml"
echo "$OK backed up to $BACKUP_DIR"

# --- 3. official mirror --------------------------------------------------
echo "== repositories: Void mirror =="
if grep -qr 'summithq' /etc/xbps.d 2>/dev/null; then
    echo "$INFO found unofficial mirror (summithq); switching to $VOID_MIRROR"
    grep -rl 'summithq' /etc/xbps.d | while read -r f; do
        cp -a "$f" "$f.pre-niri.bak"
        echo "repository=$VOID_MIRROR" > "$f"
        echo "       rewrote $f (backup: $f.pre-niri.bak)"
    done
else
    echo "$INFO no summithq mirror found; leaving existing Void repos alone"
fi
grep -rh '^repository=' /etc/xbps.d | sort -u | sed 's/^/       /'

# --- 4. DankLinux repositories ------------------------------------------
echo "== repositories: DankLinux =="
printf 'repository=%s\n' "$DMS_REPO"  > /etc/xbps.d/dms.conf
printf 'repository=%s\n' "$DANK_REPO" > /etc/xbps.d/danklinux.conf
echo "$INFO on the first sync xbps prints the DankLinux signing key fingerprint"
echo "$INFO and asks you to type y — verify it against their published fingerprint"
xbps-install -S || die "sync failed after adding DankLinux repos (bad key? remove /etc/xbps.d/dms.conf and retry)"

# --- 5. full system update ----------------------------------------------
echo "== system update (kernel 6.18 + Mesa 26.2.5) =="
echo "$INFO from a 2025-02 snapshot this is a big one; several passes are normal"
i=0
while [ "$i" -lt 8 ]; do
    i=$((i + 1))
    echo "--- update pass $i ---"
    xbps-install -Suy </dev/null || die "update pass $i failed — read the errors above before re-running"
    pending=$(xbps-install -Sun 2>/dev/null | grep -c . || true)
    [ "$pending" -eq 0 ] && break
    echo "$INFO $pending updates still pending"
done
[ "$i" -lt 8 ] || die "update still not converging after 8 passes"

# --- 6. desktop stack ----------------------------------------------------
echo "== installing niri + DMS + friends =="
PKGS="
 linux linux-headers linux-firmware-amd
 mesa-dri mesa-vulkan-radeon vulkan-loader libva-utils
 wayland-utils xorg-server-xwayland
 niri xwayland-satellite
 $DMS_PKG dms-greeter danksearch
 accountsservice polkit elogind dbus acl
 pipewire alsa-pipewire libspa-bluetooth
 bluez rtkit pavucontrol playerctl brightnessctl
 xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
 xdg-utils xdg-user-dirs dex gvfs udisks2 upower libnotify
 wl-clipboard cliphist grim slurp satty wluma wlsunset
 noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji nerd-fonts
 papirus-icon-theme mate-polkit
 cava matugen qt6ct qt5ct power-profiles-daemon i2c-tools cups-pk-helper
"
[ "$USE_NETWORKMANAGER" = yes ] && PKGS="$PKGS NetworkManager"
# shellcheck disable=SC2086
xbps-install -Sy $PKGS </dev/null || die "package installation failed — fix the errors above and re-run"

# --- 7. audio ------------------------------------------------------------
echo "== PipeWire =="
mkdir -p /etc/pipewire/pipewire.conf.d /etc/alsa/conf.d
[ -e /etc/pipewire/pipewire.conf.d/10-wireplumber.conf ] || \
    ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
[ -e /etc/pipewire/pipewire.conf.d/20-pipewire-pulse.conf ] || \
    ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
for c in 50-pipewire.conf 99-pipewire-default.conf; do
    [ -e "/etc/alsa/conf.d/$c" ] || ln -s "/usr/share/alsa/alsa.conf.d/$c" /etc/alsa/conf.d/
done
echo "$OK PipeWire configured (session manager + PulseAudio + ALSA shim)"

# --- 8. services ---------------------------------------------------------
echo "== services (runit) =="
svc_enable dbus
svc_enable elogind
svc_disable seatd     # elogind owns the seat; never run both
svc_enable rtkit
if [ "$USE_NETWORKMANAGER" = yes ]; then
    svc_enable NetworkManager
    svc_disable dhcpcd
    svc_disable wpa_supplicant
    echo "$INFO NetworkManager enabled; dhcpcd + wpa_supplicant disabled"
    echo "$INFO console networking may blip here — NetworkManager is taking over"
    sleep 5
fi
svc_enable acpid
for s in dbus elogind rtkit NetworkManager; do
    svc_enabled "$s" && echo "       enabled: $s"
done

# --- 9. greeter ----------------------------------------------------------
echo "== dms-greeter (greetd on runit) =="
if have dms-greeter; then
    echo "$INFO dms-greeter enable handles: dbus+elogind, greetd run script waiting"
    echo "$INFO on those services, _greeter groups, pam_rundir, LIBSEAT_BACKEND=logind"
    dms-greeter enable || die "dms-greeter enable failed"
    su -l "$HOST_USER" -c "dms-greeter sync" || echo "$WARN dms-greeter sync failed — rerun it later as $HOST_USER"
else
    echo "$WARN dms-greeter not installed; skipping greeter setup"
fi

# --- 10. user config, flatpak, verify ------------------------------------
echo "== user config =="
if [ ! -f "/home/$HOST_USER/.config/niri/config.kdl" ]; then
    su -l "$HOST_USER" -c "dms setup" || echo "$WARN 'dms setup' failed — run it as $HOST_USER"
else
    echo "$INFO existing niri config kept (backup: $BACKUP_DIR/niri)"
fi
# make sure DMS and pipewire autostart regardless of what dms setup wrote
for entry in 'spawn-at-startup "dms" "run"' 'spawn-at-startup "pipewire"'; do
    grep -qF "$entry" "/home/$HOST_USER/.config/niri/config.kdl" 2>/dev/null || \
        echo "$entry" >> "/home/$HOST_USER/.config/niri/config.kdl"
done
chown -R "$HOST_USER" "/home/$HOST_USER/.config/niri" 2>/dev/null || true

echo "== flatpak =="
if have flatpak; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
        && echo "$OK flathub added" || echo "$WARN could not add flathub"
fi

echo "== grub =="
if mountpoint -q /boot/efi; then
    grub-mkconfig -o /boot/grub/grub.cfg >/dev/null && echo "$OK grub menu refreshed for the new kernel"
else
    echo "$WARN /boot/efi not mounted; run 'grub-mkconfig -o /boot/grub/grub.cfg' manually"
fi

echo "== verify =="
echo "       kernels:  $(ls -1 /boot/vmlinuz-* 2>/dev/null | tr '\n' ' ')"
echo "       mesa:     $(xbps-query -p pkgver mesa 2>/dev/null)"
echo "       niri:     $(xbps-query -p pkgver niri 2>/dev/null)"
echo "       dms:      $(xbps-query -p pkgver $DMS_PKG 2>/dev/null)"
echo "       firmware: $(xbps-query -p pkgver linux-firmware-amd 2>/dev/null)"
echo "       dri:      $(ls -1 /usr/lib/dri 2>/dev/null | wc -l) driver(s) in /usr/lib/dri"
echo "       services: $(sv status dbus elogind 2>/dev/null | tr '\n' ' ')"
echo "       group:    $([ "$USE_NETWORKMANAGER" = yes ] && sv status NetworkManager 2>/dev/null | head -1)"
xbps-pkgdb -a >/dev/null 2>&1 && echo "       pkgdb:    clean" || echo "       pkgdb:    reported issues (see 'xbps-pkgdb -a')"

cat <<EOF

==================================================================
Done. Next:
  1. reboot — firmware boot menu still picks Windows by default,
     choose the WDC HDD
  2. you should land on the dms-greeter login, log in as $HOST_USER
  3. first session: niri + DMS shell; if the shell doesn't appear,
     run 'dms doctor' and check ~/.local/state/dms logs
Notes:
  * backups in $BACKUP_DIR
  * if the desktop shows no hardware acceleration, 'xbps-query -p pkgver mesa'
    should read 26.2.5; older means the update didn't complete
  * to roll the repos back: restore $BACKUP_DIR/xbps.d
  * old initramfs note: this install was built with --no-early-microcode for
    a QEMU bug; the new kernel builds a stock initramfs, which is correct
    on real hardware
==================================================================
EOF
