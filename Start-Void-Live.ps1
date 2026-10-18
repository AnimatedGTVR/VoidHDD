# Isolated live environment: no physical disks are attached.
$ErrorActionPreference = 'Stop'
$qemu = 'C:\Program Files\qemu'
$iso = 'C:\Users\jaxso\Downloads\void-live-x86_64-20250202-base.iso'
$vars = Join-Path $PSScriptRoot 'live-vars.fd'
if (-not (Test-Path $vars)) {
    Copy-Item "$qemu\share\edk2-i386-vars.fd" $vars
}
$vmArgs = @(
    '-name', 'VoidLive-Isolated',
    '-machine', 'q35,accel=tcg', '-cpu', 'max', '-smp', '4', '-m', '4096',
    '-drive', "if=pflash,format=raw,readonly=on,file=$qemu\share\edk2-x86_64-code.fd",
    '-drive', "if=pflash,format=raw,file=$vars",
    '-drive', "file=$iso,media=cdrom,readonly=on",
    '-boot', 'order=d,menu=on', '-nic', 'user,model=virtio-net-pci',
    '-vga', 'virtio', '-display', 'gtk,gl=off'
)
& "$qemu\qemu-system-x86_64.exe" @vmArgs
exit $LASTEXITCODE
