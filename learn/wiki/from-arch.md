# From Arch to Slackware

Arch and Slackware share a lot in spirit: simple, close to upstream, plain-text configuration,
and a system you are expected to understand. The differences: Slackware is the oldest
distribution still going, and it stays conservative about how the system works. It has no
systemd (init is SysVinit with BSD-style rc scripts), its package tools don't track
dependencies, and a full installation is assumed, so nearly everything is already there. Iskra
runs Slackware -current, the development branch, which is updated all the time. (Iskra itself
used to be built on CRUX, the distribution that inspired Arch.) Most Arch knowledge about
programs carries straight over; this table is the rest.

## Packages
  pacman -Syu                 iskra-update   (or: sudo sparkpkg upgrade)
  pacman -Sy                  sudo sparkpkg sync             (new lists; nothing installed)
  pacman -S foo               sudo sparkpkg install foo      (with what it needs)
  pacman -R foo               sudo sparkpkg remove foo
  pacman -Ss word             sparkpkg search word           (every repository, Arch, the AUR)
  pacman -Qi foo / -Si foo    sparkpkg info foo
  pacman -Ql foo              slpkg list-files foo ; less /var/lib/pkgtools/packages/foo-*
  pacman -F file              slpkg file-search file
  pacman -Qo /path            grep -l '^path$' /var/lib/pkgtools/packages/*   (no leading /)
  pacman -Q                   ls /var/lib/pkgtools/packages
  pacman -Qu                  iskra-update --dry
  pacman -Qdt                 sparkpkg orphans
  pacman -Qi (Required By)    sparkpkg why foo               (what needs foo)
  IgnorePkg in pacman.conf    sudo slpkg pin foo             (see: slpkg)
  undo the last change        sudo sparkpkg undo             (see: sparkpkg)
  downgrade                   sudo upgradepkg OLDER.txz      (see: pkgtools)
  /var/log/pacman.log         sparkpkg history
  makepkg / PKGBUILD          a SlackBuild and makepkg       (see: slackbuilds)
  the AUR, yay, paru          sparkpkg aur foo: builds the AUR's PKGBUILD into a Slackware
                              package                        (see: sparkpkg)
  pacman-key                  the pinned keys in /usr/share/sparkpkg/keys (see: repositories)
  pacman -U file.pkg.tar.zst  sudo upgradepkg --install-new file.txz    (see: pkgtools)
  .pacnew files               .new files (iskra-update lists them)

## Services and the system
  systemctl enable foo        sudo chmod +x /etc/rc.d/rc.foo
  systemctl disable foo       sudo chmod -x /etc/rc.d/rc.foo
  systemctl start/stop foo    sudo /etc/rc.d/rc.foo start / stop
  systemctl restart foo       sudo /etc/rc.d/rc.foo restart
  systemctl status foo        sudo /etc/rc.d/rc.foo status
  systemctl list-units        ls -l /etc/rc.d ; sudo /etc/rc.d/rc.iskra status
  journalctl -f               sudo tail -f /var/log/messages
  journalctl -u foo           /var/log/messages, or /var/log/foo.log if it has one
  journalctl -k               sudo dmesg
  systemctl suspend           iskra-sleep suspend             (see: sleep)
  systemctl poweroff/reboot   sudo poweroff / sudo reboot
  timedatectl set-timezone    sudo timeconfig, or the /etc/localtime link   (see: locale)
  locale.gen / locale-gen     nothing to generate: glibc-i18n has every locale (locale -a)
  hostnamectl set-hostname    /etc/HOSTNAME and /etc/hosts    (see: system-files)
  vconsole.conf               /etc/rc.d/rc.keymap ; setfont   (see: locale)
  mkinitcpio -P               mkinitrd, if you need an initrd at all (see: boot)
  /etc/fstab, /etc/default/grub   the same files, the same way
  systemd-timesyncd           chrony                          (see: time)
  systemd-networkd/resolved   NetworkManager
  systemd timers              crond                           (see: time)
  systemd --user services     ~/.config/iskra/autostart, run by the session
  logind.conf (lid, power)    acpid's rules in /etc/acpi/events and iskra-sleep (see: sleep)
  arch-chroot                 mount --bind /dev /proc /sys /run, then chroot (learn recovery)

## Things that differ in spirit
- Slackware doesn't record dependencies in its packages; sparkpkg works them out from the
  repositories' lists. Removing a package takes only what you name: sparkpkg orphans finds
  what nothing needs any more.
- A full Slackware is installed, so most libraries and tools you'd install on Arch are already
  there.
- Arch's programs keep Arch's layout when sparkpkg builds them (libraries in /usr/lib;
  Slackware's are in /usr/lib64); /etc/ld.so.conf.d/sparkpkg.conf finds both.
- No journal: plain-text logs through syslog in /var/log.

See also: sparkpkg, rc, system-files, repositories ; iskra-handbook ;
the Arch Wiki's package-manager table: https://wiki.archlinux.org/title/Pacman/Rosetta
