# Software: sparkpkg, slpkg and pkgtools

On Slackware every program is a package: a .txz file of its files, a description, and sometimes
a short script to run after installing. Three layers do the work:
- pkgtools, Slackware's own: installpkg puts a package file on, upgradepkg replaces one,
  removepkg takes one off. /var/lib/pkgtools/packages lists every installed package and its
  files. They don't fetch anything, and they don't know about dependencies.
- slpkg reads the repositories (Slackware -current, Iskra's, AlienBOB's, conraid's, Ponce's
  SlackBuilds), works out what a package needs, downloads it, checks its signature, and runs
  the pkgtools.
- sparkpkg, Iskra's, is the one command you use: slpkg underneath, in Iskra's order, and Arch
  and AUR recipes made into Slackware packages when no one has packaged something for
  Slackware.
Packages are ready-made, so installing takes seconds or minutes. There is one set of packages,
the system's: installing needs root (sparkpkg asks for your password itself), and everything
you install is there for every user.

## Ask (read-only)
    sparkpkg search mpv             in every repository, Arch and the AUR
    sparkpkg info mpv               what it is, and where it would come from
    sparkpkg why mpv                what needs it
    sparkpkg orphans                what was installed only for something that's gone
    sparkpkg history                what was installed, upgraded and removed, and when
    ls /var/lib/pkgtools/packages   everything installed, with versions
    less /var/lib/pkgtools/packages/mpv-*      the files of a package
    grep -l '^usr/bin/mpv$' /var/lib/pkgtools/packages/*    which package owns a file

## Change
    iskra-update                    update everything (sparkpkg upgrade, and a little more)
    sudo sparkpkg install gimp      install gimp with whatever it needs
    sudo sparkpkg remove gimp       remove it
    sudo sparkpkg undo              take back the last install, upgrade or removal
    sudo slpkg pin gimp             keep upgrades from touching it (slpkg pin -u to undo)
Add -y to answer yes to every question.

## When no one has packaged it
    sparkpkg aur foo                build foo from the AUR's recipe into a Slackware package
    sparkpkg arch foo               the same, from Arch Linux's own recipe
sparkpkg install does this by itself when the repositories don't have something. It shows you
the plan first, and offers to show an AUR recipe before building it: anyone can upload to the
AUR, so read one you don't know. Builds run as an ordinary user, never as root.

## Settings files
A package's settings files arrive as NAME.new. If you've edited yours, it stays, and the new one
waits beside it; iskra-update lists them at the end. Compare, then keep one.

References: sparkpkg help ; sparkpkg tools ; man slpkg ; man installpkg ; iskra-handbook
(Package Management) ; iskra-learn wiki sparkpkg ; iskra-learn wiki pkgtools
