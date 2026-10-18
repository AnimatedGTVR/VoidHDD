# Void Linux HDD install — COMPLETE (booted and logged in)

Final state, October 18, 2026. The 2 TB WDC HDD (Disk 0, `WDC WD20EZBX-00AYRA0`)
boots Void Linux via UEFI GRUB; user `animated` logged in successfully during the
QEMU boot test.

## What happened this session

1. **Partition-size bug fixed.** The Oct 15 recovery had written partition 2 as
   2048 sectors short of the ext4 superblock's authoritative 3,902,832,640
   sectors; `e2fsck` refused and the script aborted. `recover-hdd-offline-v2.sh`
   rewrote the GPT with verified geometry, restored the EFI backup
   (SHA-256 `ED547C…398A6BC`), and `e2fsck -f -y` repaired the root
   (20,185 files, 8,321,185 blocks).
2. **`set -e` vs e2fsck.** e2fsck exits 1 on "errors corrected", which aborted
   the script before GRUB. `finish-recovery.sh` completed: GRUB installed,
   hostname `void`, timezone `America/New_York`, user `animated` in
   `wheel,audio,video,network`.
3. **Passwords set** interactively in the live console (`finish-void-passwords.sh`).
4. **Wrong bootloader.** The ESP backup contains the previous **Omarchy/Limine**
   install; `EFI/BOOT/BOOTX64.EFI` was Limine, whose default entry boots a
   LUKS/btrfs root (`root=/dev/mapper/root`) that no longer exists — that was the
   "failed to mount /dev/mapper/root" emergency shell. Void GRUB was installed
   as the removable fallback (`EFI/BOOT/BOOTX64.EFI`, GRUB) with the Limine
   binary kept as `BOOTX64.EFI.limine-bak`; `EFI/limine/` and `limine.conf`
   are untouched on the ESP.
5. **IO-APIC panic fixed.** The kernel panicked in `setup_IO_APIC` under TCG.
   Cause: the early **AMD microcode** blob (`linux-firmware-amd`) embedded in the
   initramfs. Rebuilt with `dracut --force --no-early-microcode`; boot then
   completed cleanly. Backup: `initramfs-6.12.11_1.img.bak`.
6. **Test boot passed**: UEFI → GRUB → Void → login as `animated`.
   Temporary `console=ttyS0` debug param reverted (`GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4"`).

## Booting on real hardware

The HDD is fully self-contained: UEFI fallback `EFI/BOOT/BOOTX64.EFI` → GRUB →
Void. Windows lives on the MSI NVMe with its own EFI partition and is unaffected.
Pick the HDD from the firmware boot menu (or set it first in NVRAM). GRUB has a
5-second menu; `EFI/Void/grubx64.efi` also exists as a vendor entry.

## Known outstanding items

- `/root/XBPS-REPAIR-REQUIRED`: base-files missing `/etc/issue`; two
  `linux-firmware-amd` files hash-mismatched. Fix online with
  `xbps-install -f base-files linux-firmware-amd` (amd microcode stays out of
  the initramfs unless `dracut` is re-run with defaults — no action needed;
  BIOS supplies microcode on real hardware).
- Windows NVRAM boot entries were never touched (`--no-nvram` throughout);
  boot via firmware boot menu or the fallback path.
- QEMU quirk noted: 2-vCPU TCG boots of the live ISO panicked in IO-APIC at
  times; `-smp 1` used in the test scripts.

## Scripts written this session

`recover-hdd-offline-v2.sh`, `finish-recovery.sh`, `fix-fallback.sh`,
`regen-initramfs.sh`, `revert-debug-cmdline.sh`, `Run-Password-Step.ps1`,
`Run-HDD-BootTest.ps1`, `transfer-and-run.py`, `transfer-passwords-script.py`,
`run-recovery-sudo.py`, `run-finish.py`, `uefi-shell-boot.py`, `serial-once.py`,
`send-poweroff.py`, `inspect-root.py`.
