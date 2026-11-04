# pkgtools: installpkg, upgradepkg, removepkg, makepkg, explodepkg, pkgtool

pkgtools is Slackware's own package layer, and it is small on purpose. A package is a .txz file
(a tar archive, xz-compressed) of files laid out from /, plus a description (install/slack-desc)
and sometimes a script to run after installing (install/doinst.sh). Its name says what it is:
  x-terminal-0.9.3-x86_64-1_iskra.txz      name, version, architecture, build number and tag
The tag says who made it: none for Slackware's own, _iskra for Iskra's, alien for AlienBOB's,
cf for conraid's, _aur or _arch for one sparkpkg built from a recipe.

sparkpkg and slpkg use these tools for every change they make (see: sparkpkg, slpkg); you can
use them directly too. They don't fetch anything and they don't know about dependencies: a
package doesn't say what else it needs. That is what slpkg's repositories add.

## What is installed
/var/lib/pkgtools/packages has one plain-text file per installed package: its name, size and
description, then every file it installed (without the leading /). That folder is the whole
database. (/var/log/packages is a link to it, the place older guides mention.)
  ls /var/lib/pkgtools/packages                  everything installed
  ls /var/lib/pkgtools/packages | wc -l          how many
  less /var/lib/pkgtools/packages/mc-*           one package: its description and files
  grep -l '^usr/bin/mc$' /var/lib/pkgtools/packages/*    which package installed a file
/var/log/pkgtools/removed_packages keeps the same record for packages that were removed or
replaced by an upgrade, and /var/lib/pkgtools/scripts each installed package's doinst.sh.

## installpkg, upgradepkg, removepkg
  sudo installpkg FILE.txz                install a package file
  sudo upgradepkg FILE.txz                replace the installed package of that name with this one
  sudo upgradepkg --install-new FILE.txz  the same, or install it if it isn't there (what slpkg
                                          runs)
  sudo upgradepkg --reinstall FILE.txz    put the same version on again (a damaged install)
  sudo removepkg NAME                     remove an installed package and its files
  installpkg --warn FILE.txz              what it would add or overwrite, without doing it
  removepkg --warn NAME                   what it would remove, without doing it
upgradepkg installs the new package first, then removes whatever files of the old one the new
one doesn't have, so a running system keeps working while it happens. removepkg leaves a file
that another installed package also lists.

upgradepkg doesn't check versions, so it also goes back: upgradepkg with an older package file
puts that version on again. The packages sparkpkg built from recipes are kept in
/var/cache/sparkpkg/packages for this.

## Settings files: .new
A package's files under /etc usually arrive as name.new, and its doinst.sh decides: if you have
no such file yet, the .new becomes it; if yours is the same, the .new is deleted; if you have
edited yours, it stays and the new one waits beside it as name.new. Nothing is overwritten. After
an update, iskra-update lists every .new it finds; to see them yourself:
  find /etc -name '*.new'
  diff /etc/ly/config.ini /etc/ly/config.ini.new      compare
then keep one: move the .new over yours (sudo mv), or delete it (sudo rm).

## makepkg and explodepkg: making and opening packages
makepkg packs the folder you are in (a package's root: usr/, etc/, install/ ...) into a package.
SlackBuilds end with it (see: slackbuilds):
  cd /tmp/package-foo
  sudo makepkg -l y -c n /tmp/foo-1.0-x86_64-1_me.txz
-l y moves symbolic links into the install script (recommended); -c n leaves permissions as they
are. explodepkg does the opposite, without installing anything:
  mkdir /tmp/look && cd /tmp/look && explodepkg /path/to/foo-1.0-x86_64-1.txz
Or just look inside:  tar tf FILE.txz ; and mc opens a .txz like a folder.

## pkgtool
A menu (dialog) for the same jobs: install packages from a folder, remove installed ones, view
what's installed, and run setup scripts again (Setup -> services: tick which of Slackware's
services start at boot).
  sudo pkgtool

## Installing into another root
For a system mounted elsewhere (from the install stick, say), put ROOT= before the command:
  sudo ROOT=/mnt installpkg FILE.txz ; sudo ROOT=/mnt upgradepkg FILE.txz
  sudo ROOT=/mnt removepkg NAME
(installpkg also takes --root /mnt.)

See also: sparkpkg, slpkg, slackbuilds ; man installpkg ; man upgradepkg ; man removepkg ;
man makepkg ; man explodepkg ; man pkgtool ; iskra-handbook (the chapter Package Management)
