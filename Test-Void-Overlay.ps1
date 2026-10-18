param([int]$PortQmp = 55569, [int]$PortSerial = 55570)
$ErrorActionPreference = 'Stop'
$qemu = 'C:\Program Files\qemu'
$overlayPath = Join-Path $PSScriptRoot 'repair-test.qcow2'
$vars = Join-Path $PSScriptRoot 'test-vars2.fd'
if (-not (Test-Path $vars)) {
  Copy-Item "$qemu\share\edk2-i386-vars.fd" $vars
}
$vmArgs = @(
  '-name', 'VoidOverlayTest',
  '-machine', 'q35,accel=tcg', '-cpu', 'max', '-smp', '1', '-m', '4096',
  '-drive', "if=pflash,format=raw,readonly=on,file=$qemu\share\edk2-x86_64-code.fd",
  '-drive', "if=pflash,format=raw,file=$vars",
  '-drive', "file=$overlayPath,format=qcow2,if=none,id=hd0",
  '-device', 'virtio-blk-pci,drive=hd0',
  '-boot', 'order=cd,menu=on',
  '-nic', 'user,model=virtio-net-pci',
  '-vga', 'std', '-display', 'none',
  '-chardev', "socket,id=serial,host=127.0.0.1,port=$PortSerial,server=on,wait=off,logfile=$PSScriptRoot\test-serial.log",
  '-serial', 'chardev:serial',
  '-qmp', "tcp:127.0.0.1:$PortQmp,server=on,wait=off"
)
& "$qemu\qemu-system-x86_64.exe" @vmArgs *> "$PSScriptRoot\test-boot.log"
exit $LASTEXITCODE
