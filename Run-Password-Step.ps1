$ErrorActionPreference = 'Stop'
$work = 'C:\Users\jaxso\Work\void-diagnostics'
$qemu = 'C:\Program Files\qemu'
$iso = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void\void-live-x86_64-20250202-base.iso'
$disk = Get-Disk -Number 0
if ($disk.FriendlyName -ne 'WDC WD20EZBX-00AYRA0' -or $disk.Size -ne 2000398934016) { throw 'Target disk mismatch.' }
if ($disk.IsSystem -or $disk.IsBoot) { throw 'Target HDD is still a Windows system/boot disk.' }

Set-Disk -Number 0 -IsOffline $true
try {
    $args = @(
        '-name','VoidPasswordStep','-machine','q35,accel=tcg','-cpu','qemu64','-smp','1','-m','4096',
        '-kernel',"$work\boot\vmlinuz",'-initrd',"$work\boot\initrd",
        '-append','root=live:CDLABEL=VOID_LIVE ro init=/sbin/init rd.luks=0 rd.md=0 rd.dm=0 rd.live.overlay.overlayfs=1 console=tty0 console=ttyS0,115200',
        '-drive',"file=$iso,media=cdrom,readonly=on",
        '-drive','file=\\.\PhysicalDrive0,format=raw,if=none,id=target,cache=none,aio=threads',
        '-device','virtio-blk-pci,drive=target',
        '-nic','user,model=virtio-net-pci','-vga','virtio','-display','gtk,gl=off',
        '-chardev',"socket,id=serial,host=127.0.0.1,port=55568,server=on,wait=off,logfile=$work\password-serial.log",
        '-serial','chardev:serial','-qmp','tcp:127.0.0.1:55567,server=on,wait=off'
    )
    & "$qemu\qemu-system-x86_64.exe" @args *> "$work\password-qemu.log"
} finally {
    Set-Disk -Number 0 -IsOffline $false
}
