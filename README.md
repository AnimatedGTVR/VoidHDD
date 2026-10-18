# VoidHDD

The preserved content and tooling from recovering and finishing a **Void Linux**
install on a 2 TB WDC WD20EZBX HDD (`Disk 0`), booted and verified under QEMU.
Windows stays on its own NVMe drive and is untouched.

## Current state

| Item | Value |
| --- | --- |
| OS | Void Linux, kernel `6.12.11_1`, dracut initramfs |
| Root | ext4, UUID `244b05bb-faa3-4062-ae79-6ef9d4afe6df` on partition 2 |
| Boot | UEFI → GRUB → Void (`EFI/BOOT/BOOTX64.EFI` fallback, `EFI/Void/grubx64.efi`) |
| Hostname | `void` |
| Timezone | `America/New_York` |
| User | `animated` (groups: `wheel`, `audio`, `video`, `network`) |
| Verified | Booted in QEMU and logged in as `animated` |

To boot on real hardware, select the WDC HDD from the firmware boot menu (the
removable fallback path works with no NVRAM entry). GRUB shows a 5-second menu;
the "UEFI Firmware Settings" entry is also present.

## `xbps` — unified XBPS front-end

`xbps` is a small POSIX `sh` shim that maps short and long shortcuts onto the
matching XBPS tools, passing every remaining argument through unchanged.

```
xbps -i|--install     [args]   ->  xbps-install [args]
xbps -u|--update      [args]   ->  xbps-install -Su [args]
xbps -s|--sync        [args]   ->  xbps-install -S [args]
xbps -r|--remove      [args]   ->  xbps-remove [args]
xbps -q|--query       [args]   ->  xbps-query [args]
xbps -R|--reconfigure [args]   ->  xbps-reconfigure [args]
xbps -D|--pkgdb       [args]   ->  xbps-pkgdb [args]
```

`-I` and `-Q` are accepted as uppercase aliases for install and query.

### Behavior

- Arguments after the shortcut are forwarded verbatim, so any tool flag works:
  `xbps -i -y neovim` runs `xbps-install -y neovim`.
- Running `xbps` with no arguments prints usage.
- An unrecognized first argument prints usage to stderr and exits `2`, so a
  typo never silently installs or removes something.

### Install

```sh
sudo cp xbps /usr/local/bin/xbps
sudo chmod +x /usr/local/bin/xbps
```

### Examples

```sh
xbps -s                      # sync repository index
xbps -i neovim               # install
xbps -u                      # full system upgrade
xbps -q -Rs '^linux'         # search repositories for linux packages
xbps -q -l                   # list installed packages
xbps -r -o                   # remove orphaned packages
xbps -R linux6.12            # reconfigure a package
xbps -D -a                   # check package database integrity
```

## Planned desktop: niri + DankMaterialShell (staged, not installed)

The install is a bare base system (172 packages, no X, no Wayland, no Mesa).
The chosen desktop is **niri** (scrollable-tiling Wayland compositor) with
**DankMaterialShell** as the shell layer, plus `dms-greeter` for login.

`install-niri-dms.sh` is the reviewed, idempotent plan for turning the base
system into that desktop. Run it on the real booted system as root:

```sh
sudo sh install-niri-dms.sh 2>&1 | tee ~/niri-dms-install.log
```

Order of operations, and why:

1. **Swap the repo mirror.** The install pointed at `mirrors.summithq.com`,
   not an official Void mirror.
2. **Add the DankLinux xbps repos** (`void.danklinux.com`) — DMS, `dms-greeter`,
   `dgop`, `danksearch` are not in Void's official repositories. Signed; xbps
   shows the key fingerprint on first sync.
3. **Update the system.** Kernel `6.12.11` + the Feb-2025 snapshot predate the
   RX 9060 XT (RDNA4 / gfx1200). Mesa 25.0 was the first release with RDNA4
   support, so without this step there is no GPU acceleration at all.
   Void currently ships **kernel 6.18** and **Mesa 26.2.5**.
4. **Install the stack**: `niri`, `xwayland-satellite`, `quickshell`, `dms`,
   PipeWire, portals, fonts, `xwayland`, greeter.
5. **Services on runit**: `dbus` + `elogind` (Wayland needs a seat manager;
   never run `seatd` alongside `elogind`), optionally NetworkManager so the
   DMS network widget works.
6. **`dms-greeter enable`** does the Void-specific work: greetd `run` script
   waiting on dbus/elogind, `_greeter` video/input groups, `pam_rundir`, and
   `LIBSEAT_BACKEND=logind` (without it the greeter compositor uses seatd
   and hangs).
7. **`dms setup`** generates the niri config with keybinds + autostart.

Void does not package `waybar`, `swaync`, `swww`, `swayosd` or `ags`, which is
part of why a Quickshell-based shell (`quickshell` *is* packaged) is the
low-friction route here. Flatpak is set up as a fallback for unpackaged apps.

## Recovery history

The install was repaired in place. The main problems and fixes:

1. **Broken partition geometry.** A previous recovery wrote the root partition
   2048 sectors smaller than the ext4 superblock's authoritative size, so
   `e2fsck` refused to run. The GPT was rewritten with verified geometry
   (`recover-hdd-offline-v2.sh`), the EFI backup restored, and the filesystem
   repaired.
2. **`set -e` vs `e2fsck`.** `e2fsck` exits `1` when it corrects errors, which
   aborted the recovery script before GRUB was installed. `finish-recovery.sh`
   completed GRUB install, hostname, timezone, and user setup.
3. **Wrong bootloader.** The EFI System Partition backup carried the previous
   **Omarchy/Limine** install. `EFI/BOOT/BOOTX64.EFI` was Limine, whose default
   entry pointed at a deleted LUKS/btrfs root (`root=/dev/mapper/root`), giving
   a "failed to mount /dev/mapper/root" emergency shell. Void GRUB was installed
   as the removable fallback (`fix-fallback.sh`); the Limine binary is kept as
   `EFI/BOOT/BOOTX64.EFI.limine-bak` and `EFI/limine/` is untouched.
4. **IO-APIC panic under TCG.** The kernel panicked in `setup_IO_APIC`, caused
   by the early AMD microcode blob embedded in the initramfs. Rebuilding with
   `dracut --force --no-early-microcode` (`regen-initramfs.sh`) fixed it; the
   original image is saved as `initramfs-6.12.11_1.img.bak`. Real hardware
   applies microcode from BIOS, so nothing is lost.

### Outstanding

- `/root/XBPS-REPAIR-REQUIRED` marks package-integrity issues found during
  recovery: `base-files` is missing `/etc/issue` and two `linux-firmware-amd`
  files have hash mismatches. Fix while online with:

  ```sh
  sudo xbps -i -f base-files linux-firmware-amd
  ```

- Windows NVRAM entries were never modified (all installs used `--no-nvram`).

## Repository layout

| Path | Purpose |
| --- | --- |
| `xbps` | Unified XBPS front-end |
| `RECOVERY-STATUS.md` | Canonical record of the final state |
| `findings.md` | Early QEMU display/boot diagnostics |
| `recover-hdd-offline-v2.sh` | GPT + EFI restore, ext4 repair |
| `finish-recovery.sh` | GRUB install, hostname, user setup |
| `fix-fallback.sh` | Installs GRUB as EFI removable fallback |
| `regen-initramfs.sh` | Rebuilds initramfs without early microcode |
| `revert-debug-cmdline.sh` | Removes the temporary serial-console param |
| `finish-void-passwords.sh` | Interactive password setup (live env) |
| `Run-*.ps1` | QEMU launchers for recovery, boot testing, password step |
| `transfer*.py`, `serial-*.py`, `uefi-shell-boot.py` | Serial-console automation helpers |
| `Audit-HDD-ReadOnly.ps1`, `Inspect-HDD.ps1` | Read-only disk inspection |

Large artifacts (the 2 GiB `esp-backup.img`, kernels, disk images, logs, and
screenshots) are intentionally gitignored.
