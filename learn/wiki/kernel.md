# Kernel

## Which kernel
Iskra runs Slackware's own: the kernel-generic package, 7.2.15 at the time of writing, built by
Slackware for every computer. It has what a laptop needs to boot built in (NVMe, XFS, ext4,
vfat) and everything else as modules, which udev loads for the hardware it finds. Nothing is
compiled here: a new version arrives ready-made with iskra-update.
  installs     /boot/vmlinuz-7.2.15 (with the links vmlinuz and vmlinuz-generic),
               System.map-7.2.15, config-7.2.15.x64, and the modules in /lib/modules/7.2.15
  firmware     kernel-firmware: the files drivers load (see: firmware)
  headers      kernel-headers: for building programs, not modules

  uname -r                              the running kernel
  sparkpkg info kernel-generic          the version Slackware offers now
  less /boot/config                     its full configuration

## Updates and old kernels
When Slackware moves to a new kernel, iskra-update installs it, upgradepkg removes the old
kernel's files, and slpkg remakes GRUB's menu (grub-mkconfig). Restart to run it. If you would
like the old one kept as a fallback, make a backup of it first, with Slackware's own script:
  sudo /boot/make-kernel-backup         keeps the running kernel and its modules, as an
                                        installed package named kernel-backup-VERSION
  sudo iskra-update
  sudo grub-mkconfig -o /boot/grub/grub.cfg       so GRUB's menu has both (the backup under
                                                   Advanced options)
When the new kernel has proved itself, sudo removepkg kernel-backup takes the old one away.
To stay on the kernel you have for a while:  sudo slpkg pin kernel-generic kernel-firmware
(and slpkg pin -u to let it move again: see: slpkg).

## Modules
  lsmod                           loaded modules
  modinfo iwlwifi                 what a module is, its options
  sudo modprobe NAME              load one now
Options and blacklists go in /etc/modprobe.d (Iskra blacklists cros_usbpd_charger in
iskra-framework.conf: see: framework); modules to load at every boot go in
/etc/rc.d/rc.modules.local.

## Your own kernel
Slackware's kernel is meant to be used as it is, and Iskra does. If you need your own, the
Slackware book's last chapter (iskra-handbook, then /The Linux Kernel) builds one from
kernel.org's source; give it its own name in /boot, keep kernel-generic installed beside it,
and run grub-mkconfig.

## Kernel messages
  sudo dmesg ; sudo dmesg -w ; sudo dmesg --level=err,warn

See also: boot, firmware ; iskra-handbook (the chapter The Linux Kernel) ;
https://docs.kernel.org/
