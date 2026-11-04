# Booting: UEFI, GRUB, the kernel

The disk is GPT. Its first partition (1 GiB, FAT32) is the EFI system partition, mounted at
/boot/efi; the firmware reads GRUB from it. The installer put GRUB there twice: as "Iskra" in
the firmware's boot list, and at the fallback path every UEFI firmware tries
(EFI/BOOT/BOOTX64.EFI). GRUB's menu is /boot/grub/grub.cfg, written by grub-mkconfig from
/etc/default/grub and whatever kernels it finds in /boot, in Iskra's theme with Pasha.

The kernel is Slackware's kernel-generic: /boot/vmlinuz-7.2.15, its modules in
/lib/modules/7.2.15. GRUB loads Intel's microcode (/boot/intel-ucode.img) first, then the
kernel. There is no initrd: NVMe, XFS, ext4 and vfat are built into the kernel, and GRUB names
the root partition by its PARTUUID, which the kernel finds by itself. It resumes from
hibernation if there is an image (resume=PARTUUID=... on the kernel line), mounts / and
starts init.

## Look (read-only)
    cat /proc/cmdline                the kernel line this boot used
    ls -l /boot                      the kernel, System.map, config and microcode
    findmnt /boot/efi ; efibootmgr -v
    grep -v '^#' /etc/default/grub

## Change (deliberately)
Kernel arguments are GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub. The installer set
quiet and resume= (when there is swap). After editing it:
    sudo grub-mkconfig -o /boot/grub/grub.cfg
After a kernel upgrade, slpkg remakes the menu itself. At the GRUB menu, e edits an entry for
this boot only; Ctrl+x boots it. Secure Boot must stay off (hibernation needs it off).
If GRUB ever names the root by its filesystem UUID instead, the kernel needs an initrd to find
it; iskra-learn wiki boot shows how to make one with Slackware's mkinitrd.

References: man grub-mkconfig ; less /boot/README.initrd ; iskra-learn wiki boot
