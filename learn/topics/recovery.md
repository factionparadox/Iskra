# When something breaks

Find the first layer that failed, collect the exact error, then change one thing.
firmware -> GRUB -> kernel -> XFS root -> init and rc.S -> rc.M and rc.local (services) -> ly
-> X -> ratpoison

## An update went wrong
- Take it back:  sudo sparkpkg undo  undoes the last install, upgrade or removal (sparkpkg
  history shows what that was). Then keep the package from moving again until it's fixed:
      sudo slpkg pin NAME                (sudo slpkg pin -u NAME later)
- An older package file puts that version back:  sudo upgradepkg OLDER.txz  (upgradepkg
  doesn't mind going backwards). Packages sparkpkg built from recipes are kept in
  /var/cache/sparkpkg/packages.
- Settings: an update never overwrites a settings file you've edited; the new one sits beside
  it as NAME.new (find /etc -name '*.new'). If a program misbehaves after an update, compare
  the two: the new version may need a setting yours doesn't have.
- A program complaining of a missing library (.so) after an update: something it needs was
  upgraded without it. sudo iskra-update usually brings the rest; slpkg check-broken lists
  what slpkg installed whose dependencies are gone.
- Slackware -current's ChangeLog (iskra-handbook notes) says what changed, and often what to
  do about it.

## The desktop does not start
Log in on another console (Ctrl+Alt+F2) and read /var/log/Xorg.0.log (or
~/.local/share/xorg/Xorg.0.log). Fix ~/.xinitrc or ~/.ratpoisonrc, or move them aside: the
defaults are in /usr/share/iskra/skel/ (cp from there to put one back). If ly itself is the
trouble and won't start, /usr/lib/iskra/login gives you the ordinary text login on tty1
instead; from there, startx starts the desktop.

## A service fails
    sudo /etc/rc.d/rc.iskra status          Iskra's services
    sudo /etc/rc.d/rc.NAME status           one of Slackware's
    sudo tail -n 50 /var/log/syslog /var/log/messages     the system log; some services have
                                            /var/log/NAME.log
    sudo /etc/rc.d/rc.NAME restart
    sudo sh -x /etc/rc.d/rc.NAME start      every line the script runs, to see where it stops

## It does not boot at all
Boot the Iskra stick (the live session: user live, password live), open a terminal, and go into
the installed system:
    sudo mount /dev/nvme0n1p3 /mnt ; sudo mount /dev/nvme0n1p1 /mnt/boot/efi
    for d in dev dev/pts proc sys run sys/firmware/efi/efivars; do sudo mount --bind /$d /mnt/$d; done
    sudo chroot /mnt /bin/bash
Then, inside: put a working kernel back (sparkpkg undo, or upgradepkg a kernel-generic package
file), remake GRUB's menu, or reinstall GRUB:
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Iskra
    grub-mkconfig -o /boot/grub/grub.cfg
The XFS root can be checked only unmounted, from the stick:  sudo xfs_repair /dev/nvme0n1p3

## Logs
    sudo tail -n 100 /var/log/syslog
    sudo dmesg | tail -n 50
    less /var/log/iskra-install.log ; sparkpkg history

References: iskra-handbook ; man upgradepkg ; man slpkg ; man xfs_repair ; iskra-learn wiki rc
