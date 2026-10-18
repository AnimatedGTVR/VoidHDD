$ErrorActionPreference = 'Stop'
Get-CimInstance Win32_Process -Filter "Name='qemu-system-x86_64.exe'" |
    Where-Object { $_.CommandLine -match '-name VoidHDDReadOnly' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep -Seconds 2
& "$PSScriptRoot\Inspect-HDD.ps1" -Overlay
