$ErrorActionPreference = 'Continue'
$d = 'C:\Users\jaxso\Work\void-diagnostics'
$log = "$d\install-run.log"
function L($m) { "$([DateTime]::Now.ToString('HH:mm:ss')) $m" | Out-File -Append -Encoding utf8 $log }
"" | Out-File -Encoding utf8 $log
L "start pid=$PID user=$([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

try { Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue | Stop-Process -Force; L "stopped qemu" } catch { L "stop qemu err: $_" }
Start-Sleep -Seconds 2

try { Set-Disk -Number 0 -IsOffline $true; L "disk0 offline OK" } catch { L "disk0 offline err: $($_.Exception.Message)" }

$q = 'C:\Program Files\qemu'
$iso = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void\void-live-x86_64-20250202-base.iso'
$vars = "$d\install-vars.fd"
try { Copy-Item "$q\share\edk2-i386-vars.fd" $vars -Force; L "vars copied" } catch { L "vars err: $($_.Exception.Message)" }

$args = @(
  '-name', 'VoidInstall',
  '-machine', 'q35,accel=tcg', '-cpu', 'max', '-smp', '4', '-m', '4096',
  '-drive', "if=pflash,format=raw,readonly=on,file=$q\share\edk2-x86_64-code.fd",
  '-drive', "if=pflash,format=raw,file=$vars",
  '-drive', "file=\\.\PhysicalDrive0,format=raw,if=none,id=hd0,readonly=on,cache=none,aio=threads",
  '-device', 'virtio-blk-pci,drive=hd0',
  '-drive', "file=$iso,media=cdrom,readonly=on",
  '-boot', 'order=d,menu=on',
  '-nic', 'user,model=virtio-net-pci',
  '-vga', 'virtio', '-display', 'gtk,gl=off',
  '-device', 'qemu-xhci', '-device', 'usb-tablet',
  '-chardev', "socket,id=serial,host=127.0.0.1,port=55568,server=on,wait=off,logfile=$d\install-serial.log",
  '-serial', 'chardev:serial',
  '-qmp', 'tcp:127.0.0.1:55567,server=on,wait=off',
  '-rtc', 'base=localtime'
)

L "launching qemu"
try { & "$q\qemu-system-x86_64.exe" @args *> "$d\install-qemu.log"; L "qemu exited code=$LASTEXITCODE" } catch { L "qemu err: $($_.Exception.Message)" }
