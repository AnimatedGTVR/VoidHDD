param(
  [switch]$Gtk,
  [switch]$NoDisk
)
$ErrorActionPreference = 'Continue'
$d = 'C:\Users\jaxso\Work\void-diagnostics'
$log = "$d\direct-run.log"
function L($m) { "$([DateTime]::Now.ToString('HH:mm:ss')) $m" | Out-File -Append -Encoding utf8 $log }
"" | Out-File -Encoding utf8 $log
L "start gtk=$Gtk nodisk=$NoDisk"

try { Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue | Stop-Process -Force; L "stopped qemu" } catch { L "stop err: $_" }
Start-Sleep -Seconds 2
try { Set-Disk -Number 0 -IsOffline $true; L "disk0 offline OK" } catch { L "disk0 offline err: $($_.Exception.Message)" }

$q = 'C:\Program Files\qemu'
$iso = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void\void-live-x86_64-20250202-base.iso'

$args = @(
  '-name', 'VoidDirect',
  '-machine', 'q35,accel=tcg', '-cpu', 'max', '-smp', '4', '-m', '4096',
  '-kernel', "$d\boot\vmlinuz", '-initrd', "$d\boot\initrd",
  '-append', 'root=live:CDLABEL=VOID_LIVE ro init=/sbin/init rd.luks=0 rd.md=0 rd.dm=0 rd.live.overlay.overlayfs=1 console=tty0 console=ttyS0,115200',
  '-drive', "file=$iso,media=cdrom,readonly=on"
)
if (-not $NoDisk) {
  $args += @(
    '-drive', "file=\\.\PhysicalDrive0,format=raw,if=none,id=hd0,readonly=on,cache=none,aio=threads",
    '-device', 'virtio-blk-pci,drive=hd0'
  )
}
$args += @(
  '-nic', 'user,model=virtio-net-pci',
  '-device', 'qemu-xhci', '-device', 'usb-tablet'
)
if ($Gtk) { $args += @('-vga', 'virtio', '-display', 'gtk,gl=off') } else { $args += @('-vga', 'std', '-display', 'none') }
$args += @(
  '-chardev', "socket,id=serial,host=127.0.0.1,port=55568,server=on,wait=off,logfile=$d\direct-serial.log",
  '-serial', 'chardev:serial',
  '-qmp', 'tcp:127.0.0.1:55567,server=on,wait=off',
  '-rtc', 'base=localtime'
)

L "launching"
try { & "$q\qemu-system-x86_64.exe" @args *> "$d\direct-qemu.log"; L "exited code=$LASTEXITCODE" } catch { L "err: $($_.Exception.Message)" }
