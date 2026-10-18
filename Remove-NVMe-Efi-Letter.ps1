$ErrorActionPreference = 'Stop'
$efi = Get-Partition -DiskNumber 1 -PartitionNumber 4
if ($efi.GptType -ne '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -or $efi.Size -ne 536870912) {
    throw 'Unexpected partition'
}
if ($efi.DriveLetter) {
    Remove-PartitionAccessPath -DiskNumber 1 -PartitionNumber 4 -AccessPath ("$($efi.DriveLetter):\")
}
Get-Partition -DiskNumber 1 -PartitionNumber 4 |
    Select-Object PartitionNumber,DriveLetter,Type,Size,GptType
