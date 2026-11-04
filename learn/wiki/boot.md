# Boot

From power button to desktop, in order:

  1. UEFI firmware      finds the EFI system partition (FAT32, 1 GiB, mounted at /boot/efi)
                        and runs the boot loader named in its boot list ("Iskra"), or the
                        fallback EFI/BOOT/BOOTX64.EFI
  2. GRUB               shows Pasha's menu, loads Intel's microcode (/boot/intel-ucode.img)
                        and the kernel (/boot/vmlinuz-7.2.15), with the kernel command line
  3. kernel             Slackware's kernel-generic has NVMe, XFS, ext4 and vfat built in, so
                        it finds the root by its PARTUUID itself, with no initrd; it resumes
                        from hibernation if there is an image, mounts / and runs /sbin/init
  4. init               reads /etc/inittab: rc.S (filesystems, udev, swap), then rc.M (the
                        services) and rc.local (Iskra's services) (see: rc)
  5. ly on tty1         inittab runs ly instead of a text login (it logs you in by itself,
                        if you chose that); ly starts X and iskra-session

## GRUB
GRUB 2.16, for UEFI only. grub-install put it in /boot/efi twice (--bootloader-id=Iskra, and
--removable for the fallback path). Its settings are /etc/default/grub; /boot/grub/grub.cfg is
generated from them and from the kernels in /boot. The installer set:
  GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=PARTUUID=..."    (resume= only with a swap partition)
  GRUB_DISABLE_LINUX_UUID=true ; GRUB_DISABLE_LINUX_PARTUUID=false    name the root by PARTUUID
  GRUB_THEME=/boot/grub/themes/iskra/theme.txt                       Iskra's look
After a change:
  sudo grub-mkconfig -o /boot/grub/grub.cfg
slpkg runs that itself after a kernel upgrade (BOOTLOADER_COMMAND in /etc/slpkg/slpkg.toml).
At the menu, e edits an entry for this boot only (remove quiet to see messages, or add an
argument), and Ctrl+x boots it.
  efibootmgr -v                        the firmware's boot list

## Microcode
Intel's corrections to the processor, in /boot/intel-ucode.img (Slackware's intel-microcode
package). grub-mkconfig finds the file and has GRUB load it before the kernel.
  dmesg | grep -i microcode            "microcode updated early to revision ..."

## No initrd, usually
An initrd (initial ramdisk) is a small system the kernel starts first, to load what it needs to
reach the root. Slackware's kernel-generic already has what this laptop needs built in, and GRUB
names the root by its partition's PARTUUID, which the kernel understands without help, so Iskra
boots without one. Only a filesystem UUID needs an initrd: if grub-mkconfig ever writes root=UUID=
(the installer checks for this), make one with Slackware's mkinitrd:
  /usr/share/mkinitrd/mkinitrd_command_generator.sh -r       prints the mkinitrd command to run
  sudo mkinitrd ... -h /dev/nvme0n1p2                         that command, with -h for resume
  sudo grub-mkconfig -o /boot/grub/grub.cfg                   GRUB adds /boot/initrd.gz itself
/boot/README.initrd explains it in full.

## The kernel command line
  cat /proc/cmdline                    what this boot used
Useful at the GRUB prompt (e, then the line starting linux):
  single                               single-user mode: a root shell, no services
  modprobe.blacklist=NAME              keep a module from loading this once
  init=/bin/sh                         a root shell instead of init (mount -o remount,rw /)
Secure Boot must stay off: hibernation needs it off.

## When it does not boot
Boot the Iskra stick and chroot in (iskra-learn learn recovery): put a working kernel back,
remake GRUB's menu, or reinstall GRUB.

See also: kernel, sleep (hibernation), rc ; man grub-mkconfig ; man efibootmgr ; man mkinitrd ;
less /boot/README.initrd ; iskra-handbook (the chapter Booting)
