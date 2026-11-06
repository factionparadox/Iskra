# The escape hatch: Gentoo and Portage, in a box

Avalon's packages come from Fedora (and Flathub, for the few things only published there).
When neither has what you want, or you want to build something your own way, there is Gentoo:
a whole Gentoo system with Portage, kept in a container by **distrobox**.

    metamelayer gentoo                    # a shell in Gentoo (made the first time, then reused)
    metamelayer gentoo emerge PACKAGE     # install with Portage, Gentoo's prebuilt packages first
    metamelayer gentoo export PROGRAM     # put a Gentoo program in the Garden System's launcher
    metamelayer gentoo COMMAND...         # run anything else inside it

## What it is

- A container made from Gentoo's own **stage3** image (`docker.io/gentoo/stage3`), with the
  Gentoo package tree fetched the first time (`emerge-webrsync`).
- Portage is set to use **Gentoo's binary packages** first (`FEATURES="getbinpkg"`), so most
  things install without compiling; anything without one is compiled as usual.
- distrobox shares your **home**, your Wayland desktop, sound and devices with it, so a Gentoo
  program opens its window on the Garden System like any other, and sees your files.

## Why a box

Avalon's system is an image: read-only, replaced whole by each update. Nothing can be installed
into it by hand, which is what keeps updates and rollback reliable. The box is a separate,
writable system beside it. Portage can do anything it likes in there; it can't touch Avalon, and
Avalon's updates can't break it.

## Other boxes

    metamelayer box               # a Fedora box: dnf works normally inside it
    metamelayer box NAME          # another, separate Fedora box
    distrobox create --name arch --image docker.io/library/archlinux   # any other system

## Removing it

    distrobox rm gentoo

Your home is untouched: only the box goes.
