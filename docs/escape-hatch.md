# The escape hatch: Gentoo and Portage on Avalon

Avalon is CRUX, and CRUX's ports are a small collection. Sooner or later you will want something
that isn't in them, or a build will break at a bad moment. The escape hatch is a complete Gentoo
system kept inside Avalon, with Portage, so you can still get software when CRUX can't give it to
you.

## What it is

- A Gentoo **stage3** (the base system: glibc, compiler, coreutils, Portage, OpenRC) unpacked into
  `/var/lib/gentoo`, plus a snapshot of the Gentoo package tree in
  `/var/lib/gentoo/var/db/repos/gentoo`.
- Both come from the install disc, so the hatch works from the first boot, with or without the
  internet, even if Avalon's own build has failed.
- Portage is set to use **Gentoo's prebuilt binary packages** first (`FEATURES="getbinpkg"`):
  most things install without compiling. Gentoo signs those packages and Portage checks the
  signatures by default. Anything without a binary package is compiled as usual.

## Why it lives in its own root

CRUX (pkgutils) and Gentoo (Portage) each keep their own record of which files belong to which
package, and neither knows about the other. Installed side by side in `/`, Portage would
overwrite CRUX's libraries and CRUX would overwrite Portage's, each believing it owned them.
Builds would link against whichever version happened to be there, and the first upgrade on either
side could leave the system unbootable.

In its own root, nothing Portage does touches a CRUX file, and the reverse. The cost is space (a
couple of gigabytes, more as you install things) and that Gentoo programs use Gentoo's
libraries, not Avalon's.

## How it is joined to Avalon

`metamelayer gentoo` enters it with `chroot`. Before that it mounts into it, once per boot:

| Mounted into Gentoo | So that |
|---|---|
| `/proc`, `/sys`, `/dev` | programs see the hardware and processes |
| `/run` | programs reach D-Bus, PipeWire and the Wayland desktop |
| `/home` | your files are the same files on both sides |
| a fresh `/tmp` (plus `/tmp/.X11-unix` if present) | scratch space, and X11 programs |

It also copies in `/etc/resolv.conf` (for the internet) and, the first time, your own entry from
`/etc/passwd`, `/etc/shadow` and `/etc/group`, so you exist inside Gentoo as yourself, with the
same user ID and password.

These mounts stay until you reboot or run `sudo metamelayer gentoo unmount`.

## Using it

| Command | What it does |
|---|---|
| `sudo metamelayer gentoo` | a root shell inside Gentoo; `exit` to come back |
| `sudo metamelayer gentoo emerge PACKAGE` | install with Portage, binary packages first (any `emerge` options work) |
| `sudo metamelayer gentoo run PROGRAM [ARGS]` | run a Gentoo program as you, on Avalon's desktop |
| `sudo metamelayer gentoo sync` | update the Gentoo package tree |
| `sudo metamelayer gentoo update` | update everything installed in Gentoo |
| `sudo metamelayer gentoo unmount` | take its mounts away again |
| `sudo metamelayer gentoo remove` | unmount, then delete Gentoo (asks first; your home is not touched) |
| `sudo metamelayer gentoo COMMAND` | run any other command inside it as root |

`metamelayer portage` is the same command as `metamelayer gentoo`.

Example, a program CRUX doesn't have:

    sudo metamelayer gentoo emerge app-editors/zed
    sudo metamelayer gentoo run zed

`run` finds your Wayland socket in `/run/user/YOUR-ID` and starts the program as you, so its
window opens on the Garden System like any other. It needs `sudo` so that it knows who you are.

## When things go wrong

**The first-boot build failed.** Log in as root. Avalon's base system and the hatch are both
there: `metamelayer gentoo emerge` can fetch a tool you need to diagnose or fix the problem, then
run `avalon-firstboot` again.

**Avalon won't boot at all.** Boot the install stick, mount the laptop's disk, and use Gentoo
from there:

    mount /dev/nvme0n1p2 /mnt
    mount --bind /dev /mnt/var/lib/gentoo/dev
    mount -t proc proc /mnt/var/lib/gentoo/proc
    mount -t sysfs sysfs /mnt/var/lib/gentoo/sys
    cp /etc/resolv.conf /mnt/var/lib/gentoo/etc/
    chroot /mnt/var/lib/gentoo /bin/bash -l

From inside, Avalon's own system is not visible (that is the point of the separate root). To work
on Avalon's files, chroot into `/mnt` instead; the hatch is for getting tools, not for repairing
CRUX's package database.

## What it does not do

- It does not manage Avalon's kernel, bootloader or services. Gentoo's services (OpenRC) do not
  run; a program inside Gentoo runs only while you run it.
- Programs installed in Gentoo do not appear in the Garden System's launcher. Start them with
  `metamelayer gentoo run`.
- It is not kept up to date by `metamelayer upgrade`. Use `metamelayer gentoo update`.

## Removing it

    sudo metamelayer gentoo remove

This unmounts everything first, because `/home` is mounted inside it, and deleting
`/var/lib/gentoo` while `/home` was still mounted there would delete your home too. Never remove
it with a plain `rm -rf`.
