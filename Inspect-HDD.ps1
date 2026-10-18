param([switch]$Overlay, [switch]$Direct)
$ErrorActionPreference = 'Stop'
$disk = Get-Disk -Number 0
if ($disk.FriendlyName -ne 'WDC WD20EZBX-00AYRA0' -or $disk.Size -ne 2000398934016) {
    throw 'Disk identity changed; refusing to attach it.'
}
$qemu = 'C:\Program Files\qemu'
$iso = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void\void-live-x86_64-20250202-base.iso'
$diskArg = 'file=\\.\PhysicalDrive0,format=raw,if=none,id=hd0,readonly=on'
if ($Overlay) {
    $overlayPath = Join-Path $PSScriptRoot 'repair-test.qcow2'
    if (-not (Test-Path $overlayPath)) {
        & "$qemu\qemu-img.exe" create -f qcow2 -F raw -b '\\.\PhysicalDrive0' $overlayPath
        if ($LASTEXITCODE) { throw 'Overlay creation failed' }
    }
    $diskArg = "file=$overlayPath,format=qcow2,if=none,id=hd0"
}
$vmArgs = @(
    '-name', 'VoidHDDReadOnly',
    '-machine', 'q35,accel=tcg', '-cpu', 'max', '-smp', '1', '-m', '4096',
    '-drive', "if=pflash,format=raw,readonly=on,file=$qemu\share\edk2-x86_64-code.fd",
    '-drive', "if=pflash,format=raw,file=$PSScriptRoot\test-vars.fd",
    '-drive', "file=$iso,media=cdrom,readonly=on",
    '-drive', $diskArg,
    '-device', 'virtio-blk-pci,drive=hd0',
    '-boot', 'order=d,menu=on', '-nic', 'user,model=virtio-net-pci',
    '-vga', 'std', '-display', 'none',
    '-qmp', 'tcp:127.0.0.1:55567,server=on,wait=off'
)
if ($Direct) {
    $vmArgs = @(
        '-name','VoidHDDReadOnly','-machine','q35,accel=tcg','-cpu','qemu64','-smp','1','-m','4096',
        '-kernel',"$PSScriptRoot\boot\vmlinuz",'-initrd',"$PSScriptRoot\boot\initrd",
        '-append','root=live:CDLABEL=VOID_LIVE ro init=/sbin/init rd.luks=0 rd.md=0 rd.dm=0 rd.live.overlay.overlayfs=1 console=tty0 console=ttyS0,115200',
        '-drive',"file=$iso,media=cdrom,readonly=on",'-drive',$diskArg,'-device','virtio-blk-pci,drive=hd0',
        '-nic','user,model=virtio-net-pci','-vga','std','-display','none',
        '-chardev',"socket,id=serial,host=127.0.0.1,port=55568,server=on,wait=off,logfile=$PSScriptRoot\serial.log",
        '-serial','chardev:serial','-qmp','tcp:127.0.0.1:55567,server=on,wait=off'
    )
}
& "$qemu\qemu-system-x86_64.exe" @vmArgs *> "$PSScriptRoot\hdd-admin.log"
