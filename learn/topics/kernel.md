# The kernel: Slackware's kernel-generic

The Framework 13 Pro (Intel Core Ultra series 3, Panther Lake) needs a new kernel: older ones
lack its graphics, audio and power drivers. Slackware -current follows new kernels closely, so
Iskra runs Slackware's own, kernel-generic, 7.2.15 at the time of writing: built by Slackware,
ready-made, with NVMe, XFS, ext4 and vfat built in (so it boots without an initrd) and every
other driver as a module, loaded by udev when the hardware is there.

The package puts /boot/vmlinuz-7.2.15 (and the links vmlinuz and vmlinuz-generic),
System.map and config there, and the modules in /lib/modules/7.2.15. When Slackware moves to a
new version, iskra-update installs it, upgradepkg removes the old one, and slpkg remakes GRUB's
menu; restart to run it.

## Look
    uname -r                          the running kernel (a new one runs after a reboot)
    sparkpkg info kernel-generic      the version Slackware offers now
    less /boot/config                 its configuration
    lsmod ; sudo dmesg | less ; lspci -k   drivers, messages, which driver runs each device

## Old kernels
An upgrade replaces the old kernel and its modules. To keep a fallback, make a backup of the
running one before you update, with Slackware's own script:
    sudo /boot/make-kernel-backup     the running kernel and its modules, kept as an installed
                                      package (kernel-backup-VERSION) that upgrades don't touch
    sudo iskra-update
    sudo grub-mkconfig -o /boot/grub/grub.cfg     both kernels in GRUB's menu
When the new one has proved itself:  sudo removepkg kernel-backup
To hold the kernel you have for a while:  sudo slpkg pin kernel-generic kernel-firmware

References: man grub-mkconfig ; https://docs.kernel.org/ ; iskra-learn wiki kernel
