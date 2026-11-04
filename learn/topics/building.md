# How Iskra is built

Everything is in https://github.com/factionparadox/Iskra. Nothing is compiled on the laptop:
the packages are built ahead, on GitHub's CI, and the install stick is made from ready-made
packages only. Two parts do it.

## 1. Iskra's packages (GitHub's CI)
packages/LIST names every package Iskra builds, in order, and where each comes from: Iskra's
own SlackBuilds (packages/NAME), Ponce's SlackBuilds for -current, or Arch and AUR recipes
turned into Slackware packages by sparkpkg. For each one, build/build-packages:
1. makes a clean Slackware -current system in a folder (build/slackware-root: Slackware's own
   packages, checked against Slackware's signed CHECKSUMS.md5, installed with installpkg);
2. fetches the sources and checks them (SHA-256 or MD5; a git source is pinned to one commit);
3. builds the package in that system, as its SlackBuild says, and installs it there so the
   next ones can use it.
build/make-repo then writes PACKAGES.TXT, CHECKSUMS.md5, MANIFEST.bz2 and ChangeLog.txt, and
signs every package with Iskra's key. The result is published as the iskra repository, which
sparkpkg reads like any other (iskra-learn learn repositories).

## 2. The install stick: build/build-iso
Run on any x86_64 Linux machine with sudo (Arch in WSL2 works):   sudo build/build-iso
1. A Slackware -current system in a folder again (series a ap d l n x xap), its packages
   kept in ~/.cache/iskra/slackware for next time.
2. Iskra's slpkg, fakeroot and sparkpkg go in, each checked against Iskra's signature; then
   sparkpkg works out everything the iskra package needs that Slackware's series don't have,
   and fetches it, checking every signature.
3. liveslak, AlienBOB's Slackware Live builder (at a pinned commit), runs inside it and makes
   the stick: Slackware's series, then Iskra, with Iskra's boot menu, a live session (user
   live, password live) and iskra-install.
4. out/iskra-VERSION-x86_64.iso and its .sha256.
iskra-install copies that system from the stick to the disk (iskra-learn learn install).

## Changing X-терминал
Like every suckless program its settings are compiled in: config.h (the look and keys) and
patches.h (1 switches a patch on), in packages/x-terminal. To build your own copy on the laptop,
from a clone of the repository, iskra-learn wiki slackbuilds has the steps: edit config.h,
run the SlackBuild, upgradepkg the result, and pin it so sparkpkg upgrade leaves it alone.

## On this computer
    cat /usr/share/iskra/version          the Iskra version installed
    sparkpkg info iskra-desktop           Iskra's own packages, like any other
    ls /var/lib/pkgtools/packages | grep _iskra    every package Iskra built

Licences: Iskra is GPL-3.0; each program keeps its own (its HOMEPAGE in the .info file leads
to it); the Russian material keeps its own (public domain, CC BY-SA, and Между нами's CC
BY-NC-ND, copied only for your personal use).
