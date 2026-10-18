# Launch a UEFI QEMU VM that boots the Void live ISO with the physical
# WD 2TB disk (PhysicalDrive0) passed through for installation.
param(
    [string]$Accel = 'whpx',
    [string]$Disk  = '\\.\PhysicalDrive0',
    [int]$Mem      = 4096,
    [int]$Smp      = 4,
    [string]$Share = ''
)

$dir  = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void'
$q    = 'C:\Program Files\qemu'
$iso  = "$dir\void-live-x86_64-20250202-base.iso"
$vars = "$dir\void-vars.fd"
$code = "$q\share\edk2-x86_64-code.fd"
$log  = "$dir\run-vm.log"

$qargs = @(
    '-name', 'VoidInstaller',
    '-machine', "q35,accel=$Accel",
    '-cpu', 'max',
    '-smp', "$Smp",
    '-m', "$Mem",
    '-drive', "if=pflash,format=raw,readonly=on,file=$code",
    '-drive', "if=pflash,format=raw,file=$vars",
    '-drive', "file=$Disk,format=raw,if=none,id=hd0,cache=writeback,aio=threads",
    '-device', 'virtio-blk-pci,drive=hd0',
    '-drive', "file=$iso,media=cdrom,readonly=on",
    '-boot', 'order=d,menu=on',
    '-netdev', 'user,id=net0',
    '-device', 'virtio-net-pci,netdev=net0',
    '-device', 'qemu-xhci',
    '-device', 'usb-tablet',
    '-vga', 'std',
    '-display', 'sdl',
    '-qmp', 'tcp:127.0.0.1:55557,server,nowait',
    '-rtc', 'base=localtime'
)

if ($Share) {
    $qargs += @(
        '-drive', "file=fat:rw:$Share,if=none,id=share",
        '-device', 'virtio-blk-pci,drive=share'
    )
}

"CMD: $q\qemu-system-x86_64.exe $($qargs -join ' ')" | Out-File $log -Encoding utf8
$sw = [Diagnostics.Stopwatch]::StartNew()
& "$q\qemu-system-x86_64.exe" @qargs *>> $log
$sw.Stop()
"EXIT=$LASTEXITCODE after $([int]$sw.Elapsed.TotalSeconds)s" | Out-File -Append $log -Encoding utf8
