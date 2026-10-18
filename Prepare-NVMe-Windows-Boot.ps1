$ErrorActionPreference = 'Stop'
$work = 'C:\Users\jaxso\Work\void-diagnostics'
Start-Transcript -Path "$work\nvme-boot-result.log" -Force | Out-Null
try {
$disk = Get-Disk -Number 1
$cpart = Get-Partition -DriveLetter C

if ($disk.FriendlyName -ne 'MSI M450 1TB' -or $disk.Size -ne 1000204886016) {
    throw 'Disk 1 is not the expected MSI M450 1TB NVMe.'
}
if ($cpart.DiskNumber -ne 1 -or $cpart.PartitionNumber -ne 2) {
    throw 'C: is not the expected NVMe partition.'
}
if (Get-Partition -DiskNumber 1 | Where-Object GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}') {
    throw 'The NVMe already has an EFI System Partition; inspect it instead of creating another.'
}

Get-Disk -Number 1 | Format-List * > "$work\nvme-before.txt"
Get-Partition -DiskNumber 1 | Format-List * >> "$work\nvme-before.txt"

$efiSize = 512MB
$newCSize = $cpart.Size - $efiSize
$supported = Get-PartitionSupportedSize -DriveLetter C
if ($newCSize -lt $supported.SizeMin) {
    throw 'Windows cannot safely shrink C: by 512 MiB.'
}

Resize-Partition -DriveLetter C -Size $newCSize
$efi = New-Partition -DiskNumber 1 -Size $efiSize -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -AssignDriveLetter
Format-Volume -Partition $efi -FileSystem FAT32 -NewFileSystemLabel 'SYSTEM' -Confirm:$false
$letter = ($efi | Get-Volume).DriveLetter
if (-not $letter) { throw 'The new EFI partition has no drive letter.' }

& bcdboot.exe C:\Windows /s "${letter}:" /f UEFI
if ($LASTEXITCODE) { throw "bcdboot failed with exit code $LASTEXITCODE" }

Get-ChildItem "${letter}:\EFI\Microsoft\Boot\bootmgfw.efi" -ErrorAction Stop
Get-Partition -DiskNumber 1 | Format-List * > "$work\nvme-after.txt"
Write-Output "NVME_WINDOWS_BOOT_READY drive=${letter}:"
} finally {
    Stop-Transcript | Out-Null
}
