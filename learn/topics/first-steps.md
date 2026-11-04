# First steps

Press Super+? for the keys. Ctrl+Super+Space opens the menu; everything in it is a plain command you
can also type. Super+Return opens a terminal.

## Three places to learn from
- These lessons (iskra-learn): how THIS system is put together, and why.
- The Slackware book, offline (iskra-handbook): how Slackware is meant to be used: the shell,
  users, filesystems, networking, the package tools, the kernel.
- Manual pages (man installpkg, man slpkg, man ratpoison, ...): exactly what the commands accept.

## Start by looking, not changing
    iskra-learn doctor             what is running, in one screen
    iskra-learn explain "sparkpkg upgrade"   what it would do (NOT run)
    ls -l /etc/rc.d                  the services; the executable ones start at boot
    sparkpkg history                 what was installed, upgraded and removed, and when
    ls /var/lib/pkgtools/packages    every installed package and its version
    fastfetch                        the system at a glance, with Pasha

## Software
    sparkpkg search word           look for something
    sudo sparkpkg install foo      install it, with whatever it needs
    sudo sparkpkg install libreoffice   LibreOffice, ready-made (AlienBOB's)
sparkpkg help shows the rest; iskra-learn learn packages explains it.

## Keeping up to date
    iskra-update                   (or Ctrl+Super+Space -> System -> Update everything)
    iskra-update --dry             only show what would change
It fetches the latest package lists from every repository (Slackware -current first), then
replaces every package that has a newer version: ready-made packages, so it takes minutes, not
hours. Anything sparkpkg built from an Arch or AUR recipe is rebuilt if its recipe is newer.
Then it fetches the newest Slackware book. If the kernel changed, restart to use it.

Changed your mind?  sudo sparkpkg undo  takes back the last install, upgrade or removal.
Settings files under /etc are never overwritten once you have edited them: the new version
arrives beside yours as NAME.new, and iskra-update lists every one. Compare them (diff), then
keep one.

## Your files and the system's
Your settings are in your home folder (~/.ratpoisonrc, ~/.config/...), and an update never
touches them. The system's settings are plain files in /etc that you may edit directly.
