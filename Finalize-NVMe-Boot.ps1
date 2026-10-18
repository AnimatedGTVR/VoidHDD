$ErrorActionPreference = 'Stop'
$log = 'C:\Users\jaxso\Work\void-diagnostics\nvme-finalize.log'
Start-Transcript -Path $log -Force | Out-Null
try {
    $efi = Get-Partition -DiskNumber 1 | Where-Object GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
    if (-not $efi -or $efi.Size -ne 536870912) { throw 'Expected 512 MiB NVMe EFI partition not found.' }
    if (-not $efi.DriveLetter) { $efi | Add-PartitionAccessPath -AssignDriveLetter; $efi = $efi | Get-Partition }
    $letter = $efi.DriveLetter
    $source = "${letter}:\EFI\Microsoft\Boot\bootmgfw.efi"
    $fallbackDir = "${letter}:\EFI\BOOT"
    New-Item -ItemType Directory -Path $fallbackDir -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination "$fallbackDir\BOOTX64.EFI" -Force
    Get-Item $source,"$fallbackDir\BOOTX64.EFI","${letter}:\EFI\Microsoft\Boot\BCD" |
        Select-Object FullName,Length,LastWriteTime
    Get-FileHash $source,"$fallbackDir\BOOTX64.EFI" -Algorithm SHA256
    & bcdedit.exe /enum firmware
    Write-Output 'NVME_UEFI_FALLBACK_READY'
} finally {
    Stop-Transcript | Out-Null
}
