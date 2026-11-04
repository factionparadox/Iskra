# Iskra's own tools

Slackware gives you small, plain tools (installpkg, removepkg, the rc.d scripts) and expects you
to know them. Iskra adds a few of its own on top: one command for software, one to keep
everything current, fingerprint for sudo, sleep without fuss, and the book kept offline. They
are plain shell scripts in /usr/bin: read them with  less /usr/bin/NAME  whenever you want to
know exactly what one does.

## sparkpkg: software
  sparkpkg install foo ; remove foo ; upgrade ; search word ; info foo ; undo ; history
Everything about it is on its own page: see sparkpkg. sparkpkg tools lists Slackware's own
package tools beside it (see: pkgtools).

## iskra-update: keeping everything current
  iskra-update                    sparkpkg upgrade: Slackware -current and the other
                                  repositories (ready-made packages, nothing compiled), then
                                  anything sparkpkg built from an Arch or AUR recipe that has a
                                  newer one; then the newest Slackware book
  iskra-update --dry              only show what would change
It also puts Iskra's /etc/os-release back if an upgrade of Slackware's aaa_base brought
Slackware's, and at the end lists any settings files that arrived as .new beside your own
(see: pkgtools). After a new kernel, restart to use it; GRUB's menu is remade on the way.
If an update breaks something:  sudo sparkpkg undo.

## iskra-fingerprint: fingerprint for sudo
The Framework's fingerprint reader works through fprintd and libfprint. iskra-fingerprint sets
it up for sudo, and for programs that ask for your password through polkit.

  iskra-fingerprint               enrol a finger (touch the reader about 10 times), then
                                  switch fingerprint on for sudo
  iskra-fingerprint add           enrol another finger
  iskra-fingerprint off           back to passwords only (enrolled fingers are kept)
  iskra-fingerprint forget        delete your enrolled fingers

With it on, sudo asks for a finger first; give it 10 seconds or press Ctrl+C, and it asks for
your password as usual. The login screen (ly) and the screen lock (slock) keep using your
password. It works by adding one line, pam_fprintd, to the top of /etc/pam.d/sudo and
/etc/pam.d/polkit-1. An upgrade of sudo or polkit keeps your edited file, and puts its own
beside it as .new (see: pkgtools): keep yours. See: users (PAM).

## iskra-handbook: the Slackware book, offline
  iskra-handbook                  the book in less (/ searches, q quits)
  iskra-handbook mc               beside this wiki, in Midnight Commander
  iskra-handbook notes            Slackware -current's ChangeLog
  iskra-handbook update           fetch the newest book from docs.slackware.com now
See: handbook.

## iskra-sleep and iskra-sleepcheck
  iskra-sleep suspend ; iskra-sleep hibernate     sleep now (Super+z suspends)
  iskra-sleepcheck                does sleep reach S0ix? (suspends for a minute)
See: sleep, framework.

## The rest
  iskra-learn         these lessons and this wiki; explain, doctor, search
  iskra-menu          Ctrl+Super+Space: the menus
  iskra-session       the X session: one line per piece of the desktop
  iskra-open          the programs behind the Ctrl+Super chords
  iskra-term          a titled X-терминал window running a command (every menu uses it)
  iskra-keys          Super+?: the keys
  iskra-overview      Super+Tab: pick a window or a workstation
  iskra-width         Super+r: this window's width, 33% -> 50% -> 67% -> 100%
  iskra-workstations  makes ratpoison's workstations 1-9 at login
  iskra-screenshot    Print, Shift+Print: into ~/Pictures/Screenshots and the clipboard
  iskra-battery       low-battery warnings, and hibernation at 4 %
  iskra-nightlight    redshift: a warmer screen after sunset, from your time zone
  iskra-vpn           Ctrl+Super+p: VPN connections on and off (see: network)
  iskra-acme, iskra-plumb   acme and the plumber, with Plan 9's PATH (iskra-learn learn plan9)
  iskra-russian, iskra-content   the Russian kit (iskra-learn learn russian)
  iskra-install       on the install stick: puts Iskra on the disk (iskra-learn learn install)

See also: sparkpkg, pkgtools, handbook, users, sleep ; sparkpkg help
