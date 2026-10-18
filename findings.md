# Void/QEMU diagnostic findings

Tests used QEMU 11.1.0, q35/TCG, four vCPUs, 4 GiB RAM, UEFI, and the existing Void 20250202 base ISO. No physical disk was attached to any diagnostic VM.

- Standard VGA with display disabled reached the live login prompt.
- Standard VGA with SDL and GTK showed corrupted graphics during boot. QMP remained responsive during these checks; the earlier Windows application hang was not reproduced.
- VirtIO VGA with GTK (`-vga virtio -display gtk,gl=off`) reached login with readable graphics. Root login succeeded and `void-installer` opened its welcome dialog (installer.png).
- The original installation target and its filesystem have not been tested or modified. The 2 TB HDD includes the Windows EFI system partition.

Start-Void-Live.cmd launches an isolated live VM using VirtIO VGA and GTK. It deliberately has no installation target attached. This validates a boot/display workaround, not completion of an HDD installation.

Original launcher: C:\Users\jaxso\AppData\Local\Temp\opencode\void\run-vm.ps1. It was left unchanged.
