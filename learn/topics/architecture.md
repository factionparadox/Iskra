# How Iskra fits together

Iskra is Slackware64 -current, the rolling development branch of Slackware, with a small X11
desktop on top: ratpoison, polybar, dmenu and Plan 9's acme. Init is SysVinit with Slackware's
BSD-style rc scripts; there is no systemd, though elogind keeps track of logins. Slackware's
own kernel-generic (7.2.15), Mesa 26, PipeWire, NetworkManager, eudev and GRUB 2.16 do the
work underneath. Everything arrives ready-made: Slackware's packages, Iskra's own (built by
GitHub's CI and signed), AlienBOB's and conraid's, all through sparkpkg. The `iskra` package
has no files of its own; what it requires is the whole of Iskra, so installing it installs
everything.

## From power button to desktop
1. UEFI firmware starts GRUB from the EFI partition (/boot/efi).
2. GRUB loads Intel's microcode and the kernel (/boot/vmlinuz-7.2.15). No initrd: the kernel
   has NVMe and XFS built in, and finds the root by its PARTUUID.
3. The kernel mounts the XFS root, or resumes from hibernation (resume= on the kernel line),
   and starts init, process 1.
4. init reads /etc/inittab: /etc/rc.d/rc.S prepares the system (udev, swap, filesystems), then
   /etc/rc.d/rc.M starts Slackware's services whose scripts are executable (the system log,
   D-Bus, elogind, NetworkManager, Bluetooth, acpid, crond), then rc.local, which starts
   Iskra's through rc.iskra: the firewall, TLP, thermald, intel_lpmd, chrony, the tutor.
5. inittab runs ly on tty1 instead of a text login (it logs you in by itself if you chose that).
6. ly starts X and the session in /usr/share/xsessions/iskra.desktop: iskra-session.
7. iskra-session starts sound, the bar, notifications, the screen lock, then ratpoison.

## Where things live
/etc/rc.d/                    the boot scripts and one script per service (rc.NAME)
/etc/rc.d/rc.iskra            Iskra's services, started from rc.local
/etc/slpkg/                   where packages come from, in which order (repositories.toml)
/var/lib/pkgtools/packages    every installed package, one file each, listing its files
/var/cache/sparkpkg/packages  packages sparkpkg built from Arch and AUR recipes
/etc/iskra/                   ratpoisonrc, polybar.ini, Xresources
~/.ratpoisonrc ~/.config/polybar/config.ini   your settings (they include the defaults)
/usr/share/iskra/learn        these lessons and the wiki
/var/lib/iskra/russian        the Russian material, once downloaded

## Look for yourself (nothing here changes anything)
    iskra-learn doctor
    ls -l /etc/rc.d                     which services start at boot (the executable ones)
    ls /var/lib/pkgtools/packages | wc -l    how many packages are installed
    iskra-update --dry                  what an update would change
    less "$(command -v iskra-session)"

Next: iskra-learn learn install (what the installer did, step by step).
