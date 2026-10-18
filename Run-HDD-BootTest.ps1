$ErrorActionPreference = 'Stop'
$work = 'C:\Users\jaxso\Work\void-diagnostics'
$qemu = 'C:\Program Files\qemu'
$disk = Get-Disk -Number 0
if ($disk.FriendlyName -ne 'WDC WD20EZBX-00AYRA0' -or $disk.Size -ne 2000398934016) { throw 'Target disk mismatch.' }
if ($disk.IsSystem -or $disk.IsBoot) { throw 'Target HDD is still a Windows system/boot disk.' }
$vars = Join-Path $work 'boot-test-vars.fd'
if (-not (Test-Path $vars)) { Copy-Item (Join-Path $work 'test-vars.fd') $vars }

Set-Disk -Number 0 -IsOffline $true
try {
    $args = @(
        '-name','VoidHDDBootTest','-machine','q35,accel=tcg','-cpu','qemu64','-smp','1','-m','4096',
        '-drive',"if=pflash,format=raw,readonly=on,file=$qemu\share\edk2-x86_64-code.fd",
        '-drive',"if=pflash,format=raw,file=$vars",
        '-drive','file=\\.\PhysicalDrive0,format=raw,if=none,id=target,cache=none,aio=threads',
        '-device','virtio-blk-pci,drive=target',
        '-boot','order=c,menu=on',
        '-nic','user,model=virtio-net-pci','-vga','virtio','-display','gtk,gl=off',
        '-chardev',"socket,id=serial,host=127.0.0.1,port=55568,server=on,wait=off,logfile=$work\boot-test-serial.log",
        '-serial','chardev:serial','-qmp','tcp:127.0.0.1:55567,server=on,wait=off'
    )
    & "$qemu\qemu-system-x86_64.exe" @args *> "$work\boot-test-qemu.log"
} finally {
    Set-Disk -Number 0 -IsOffline $false
}
