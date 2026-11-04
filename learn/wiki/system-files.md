# The files that are the system: inittab, fstab, rc.local and the rest

On Slackware the system is its files. There is no central settings file and nothing to rebuild:
you edit a file in /etc, and it takes effect at the next boot, or when you restart what reads it.
Keep a copy before a large change (sudo cp /etc/fstab /etc/fstab.old).

## The computer's name, the time zone, the keyboard
  /etc/HOSTNAME             this computer's name, with .localdomain (rc.M sets it at boot);
                            /etc/hosts has the same name beside 127.0.1.1
  /etc/localtime            a link to the time zone in /usr/share/zoneinfo (see: locale)
  /etc/hardwareclock        UTC: the hardware clock keeps UTC
  /etc/rc.d/rc.keymap       the console keyboard: loadkeys uk.map (X has its own: see: locale)
  /etc/profile.d/lang.sh    LANG=en_GB.UTF-8, for every login shell
The installer wrote all of these from your answers. For a new name, edit /etc/HOSTNAME and
/etc/hosts and restart. For the time zone,  sudo timeconfig  asks, or change the link
yourself (see: locale).

## /etc/fstab
What rc.S checks and mounts at boot: the root (XFS) and /boot/efi by UUID, the swap
partition, /dev/pts, /proc and /dev/shm (see: filesystems). After an edit, sudo mount -a tries it.

## /etc/inittab
What init runs. The parts Iskra relies on:
  id:3:initdefault:                       boot to runlevel 3 (multi-user)
  si:S:sysinit:/etc/rc.d/rc.S             the boot script
  rc:2345:wait:/etc/rc.d/rc.M ; l0:0:wait:/etc/rc.d/rc.0 ; l6:6:wait:/etc/rc.d/rc.6
  c1:12345:respawn:/sbin/agetty --noclear -n -l /usr/lib/iskra/login 38400 tty1 linux
                                          tty1: ly, Iskra's login screen (the one line
                                          iskra-desktop changes)
  c2 ... c6                               text logins on tty2 to tty6 (Ctrl+Alt+F2 ...)
/usr/lib/iskra/login is a short script: it runs ly, and if ly isn't installed or won't start,
the ordinary text login instead, so there is always a way in. After an edit,  sudo telinit q
makes init read the file again. For a plain text login on tty1, give c1 the same command as c2,
with tty1.

## rc.local and rc.local_shutdown
/etc/rc.d/rc.local runs at the end of every boot, and /etc/rc.d/rc.local_shutdown first at every
shutdown and restart: the place for your own commands. iskra-desktop added a line to each, to
start and stop Iskra's services (see: rc):
  [ -x /etc/rc.d/rc.iskra ] && /etc/rc.d/rc.iskra start
  [ -x /etc/rc.d/rc.iskra ] && /etc/rc.d/rc.iskra stop

## Other files that are the system
  /etc/default/grub         the kernel command line, GRUB's look (see: boot)
  /etc/slpkg/               where packages come from, and how (see: slpkg, repositories)
  /etc/sudoers.d/iskra      who may use sudo (see: users)
  /etc/ly/config.ini        the login screen, automatic login
  /etc/X11/xorg.conf.d/30-iskra.conf   X's keyboard, touchpad and graphics driver
  /etc/nftables.d/iskra.nft            the firewall (see: network)
  /etc/iskra/               ratpoisonrc, polybar.ini, Xresources
  /etc/profile.d/iskra.sh   EDITOR and the video settings for every login
  /etc/acpi/events/         acpid's rules: the lid and the power button run iskra-sleep
                            (elogind leaves them alone: /etc/elogind/logind.conf.d; see: sleep)
  /etc/os-release           the system's name: Iskra (iskra-update puts it back when an
                            upgrade of Slackware's aaa_base brings Slackware's)

## Settings files and updates
Files that come in a package are never overwritten by an update once you have edited them: the
package's new version arrives beside yours as NAME.new, and iskra-update lists every one it
finds (see: pkgtools). Compare, then keep one.

## Undoing a change
For a file you changed, your copy. For a package, sparkpkg undo takes back the last install,
upgrade or removal (see: sparkpkg). There are no snapshots of the whole system.

See also: rc, boot, filesystems, pkgtools ; man fstab ; man inittab ; man agetty ;
iskra-handbook
