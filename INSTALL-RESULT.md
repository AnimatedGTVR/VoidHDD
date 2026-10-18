# Install result — niri + DankMaterialShell

Outcome of the first real run of `install-niri-dms.sh`. It was executed inside a
chroot against the offline install (`run-in-chroot.sh` drives that), driven over
the QEMU serial console, so the same packages are on the real disk.

## What is on the disk now

| | before | after |
|---|---|---|
| packages | 172 | **547** |
| kernel | 6.12.11_1 (2025-02) | **6.18.57_1** (`linux` metapackage 6.18_1) |
| mesa | not installed | **26.2.5_1** |
| amd firmware | 20250109 | **20260810_1** |
| DRI drivers | none | **51** in `/usr/lib/dri` |
| compositor | — | **niri 26.04_2** |
| shell | — | **dms 1.6.3_2** (quickshell 0.3.2_1) |
| greeter | — | **dms-greeter 1.6.2_1** |
| X compat | — | xwayland-satellite 0.8.3_1 + xorg-server-xwayland 24.1.13_2 |
| audio | — | pipewire 1.6.9_1 + wireplumber 0.5.18_1 |

Repositories: official `repo-default.voidlinux.org/current` plus the two
DankLinux repos. The DankLinux key was imported non-interactively with
fingerprint `ba:bd:2e:bf:4c:64:7f:ad:c0:67:16:49:9d:6c:7d:7f`
("AvengeMedia <AvengeMedia.US@gmail.com>").

## Things the script had to be taught

1. **xbps must update itself first.** Coming from a 2025-02 snapshot the first
   `xbps-install -Suy` aborts with *"The 'xbps' package must be updated"*. The
   script now runs `xbps-install -Suy xbps` up to 4 times ahead of the real
   update. It went 0.59.2_3 → 0.60.7_1, along with glibc 2.41 and OpenSSL 3.6.5,
   as its own transaction.
2. **`dms setup` is a menu-driven TUI.** With stdin coming from a pipe it reads
   EOF, prints "No configurations selected. Exiting." and writes nothing. The
   script now only calls it when `[ -t 0 ]`, and otherwise writes a starter
   `~/.config/niri/config.kdl` itself (it also creates the directory — the old
   version tried to append to a file in a directory that did not exist yet).
3. **`dms-greeter sync` and `dms setup` invoke `sudo` themselves.** Offline that
   can never work (no terminal, password unknown), and `dms-greeter sync` also
   needs root to rewrite `/etc/greetd`. The script now pre-adds `_greeter` and
   `input` membership as root, and the sync was run **as root**, which completed
   ("=== Sync Complete ===").
4. **`getent` inside vs outside the chroot.** The greeter's user check has to run
   inside (`chroot /mnt getent group _greeter`), because the live ISO has no
   `_greeter` group; likewise `chown animated` from the live side is wrong since
   uid 1000 there is `anon`. Use numeric ids or go through the chroot.

## Files with a legitimate post-install difference

`xbps-pkgdb -a` is otherwise clean. The one reported failure is expected:

```
ERROR: greetd: files check FAILED   (/etc/sv/greetd/run)
```

`dms-greeter enable` rewrites that run script (it adds the `sv check dbus` /
`sv check elogind` gate and `LIBSEAT_BACKEND=logind`), so its hash no longer
matches the package. Keep it — that is the working configuration.

## Final service state (runit)

Enabled: `dbus`, `elogind`, `greetd`, `rtkit`, `NetworkManager`, `acpid`,
`chronyd`, `sshd`, `udevd`, `agetty-tty1..6`.
Disabled: `dhcpcd`, `wpa_supplicant` (NetworkManager owns the NIC now), `seatd`
(elogind owns the seat — never run both).

`/var/service` is a symlink to `../run/runit/runsvdir/current`; when inspecting
it from a chroot the `/run` bind mount makes the host view show the *live*
system's services instead. Check the chroot view.

## Config

`/etc/greetd/config.toml`:

```
vt = 7
[default_session]
command = "env LIBSEAT_BACKEND=logind DMS_VOID=1 /usr/bin/dms-greeter --command niri --cache-dir /var/cache/dms-greeter"
user = "_greeter"
```

`animated` is in `wheel, audio, video, input, network, kvm, _greeter` (plus the
default groups); `_greeter` is in `video, input`.

`~/.config/niri/config.kdl` — a starter file with `prefer-no-csd`, gaps/border
theme, and `spawn-at-startup` for `pipewire` and `dms run`.

## Follow-ups when you boot it for real

1. Log in, then run `dms setup` as `animated` — the TUI configures keybinds and
   terminal properly (it will ask for your password to add the `input` group the
   Caps Lock OSD needs; that is already done, so it should pass through).
2. Run `dms-greeter sync` again as `animated` if you want the login screen to
   mirror *your* theme instead of root's.
3. `xbps-remove -o` to clear the old 6.12.11_1 and 6.12.113_1 kernels once
   6.18 boots, which also drops the `[warn]` about multiple kernels.
4. Handle `/root/XBPS-REPAIR-REQUIRED` — the update has now reinstalled
   `base-files` and `linux-firmware-amd`, so just confirm `/etc/issue` exists and
   delete that marker.

## Logs

`/root/niri-dms-install.log` (on the disk) — full transcript, ~11k lines.
`/root/pre-sync.log` — the DankLinux key import.
Backups live in `/root/niri-dms-backup-<timestamp>/`.
