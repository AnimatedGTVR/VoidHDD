$q = 'C:\Program Files\qemu'
$d = 'C:\Users\jaxso\Work\void-diagnostics'
$iso = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void\void-live-x86_64-20250202-base.iso'
$args = @(
  '-machine', 'q35,accel=whpx', '-cpu', 'max', '-smp', '4', '-m', '4096',
  '-kernel', "$d\boot\vmlinuz", '-initrd', "$d\boot\initrd",
  '-append', 'root=live:CDLABEL=VOID_LIVE ro console=ttyS0,115200 rd.live.overlay.overlayfs=1',
  '-drive', "file=$iso,media=cdrom,readonly=on",
  '-display', 'none', '-serial', "file:$d\whpx-direct.log", '-no-reboot'
)
& "$q\qemu-system-x86_64.exe" @args *> "$d\whpx-direct-err.log"
