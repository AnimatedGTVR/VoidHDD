$ErrorActionPreference = 'Stop'
$work = 'C:\Users\jaxso\Work\void-diagnostics'
$qemu = 'C:\Program Files\qemu'
$iso = 'C:\Users\jaxso\AppData\Local\Temp\opencode\void\void-live-x86_64-20250202-base.iso'
"$(Get-Date -Format o) audit start" | Out-File "$work\audit-launch.log" -Encoding utf8
$disk = Get-Disk -Number 0
if ($disk.FriendlyName -ne 'WDC WD20EZBX-00AYRA0' -or $disk.Size -ne 2000398934016) {
    throw 'Disk identity changed; refusing to attach it.'
}
Get-CimInstance Win32_Process -Filter "Name='qemu-system-x86_64.exe'" |
    Where-Object { $_.CommandLine -match 'VoidHDDAudit' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
"$(Get-Date -Format o) disk stays online; QEMU attachment is readonly" | Out-File "$work\audit-launch.log" -Append -Encoding utf8
$vmArgs = @(
    '-name','VoidHDDAudit','-machine','q35,accel=tcg','-cpu','qemu64','-smp','1','-m','4096',
    '-kernel',"$work\boot\vmlinuz",'-initrd',"$work\boot\initrd",
    '-append','root=live:CDLABEL=VOID_LIVE ro init=/sbin/init rd.luks=0 rd.md=0 rd.dm=0 rd.live.overlay.overlayfs=1 console=tty0 console=ttyS0,115200',
    '-drive',"file=$iso,media=cdrom,readonly=on",
    '-drive','file=\\.\PhysicalDrive0,format=raw,if=none,id=hd0,readonly=on,cache=none,aio=threads',
    '-device','virtio-blk-pci,drive=hd0','-nic','user,model=virtio-net-pci',
    '-vga','std','-display','none',
    '-chardev',"socket,id=serial,host=127.0.0.1,port=55568,server=on,wait=off,logfile=$work\audit-serial.log",
    '-serial','chardev:serial','-qmp','tcp:127.0.0.1:55567,server=on,wait=off'
)
try {
    "$(Get-Date -Format o) launching qemu" | Out-File "$work\audit-launch.log" -Append -Encoding utf8
    & "$qemu\qemu-system-x86_64.exe" @vmArgs *> "$work\audit-qemu.log"
} finally {
    "$(Get-Date -Format o) qemu exit=$LASTEXITCODE" | Out-File "$work\audit-launch.log" -Append -Encoding utf8
}
