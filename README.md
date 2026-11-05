# Avalon

Avalon is a Linux system for the Framework Laptop 13 Pro, built on **CRUX**: a minimal base you
compile into your own, with the **Garden System** on top, a desktop whose look comes from the
late-1990s PlayStation game *Pixygarden* (an original design in its spirit, not the game's art).
Its keeper is **Pasha**, a little arctic wolf pup.

The first release is **Avalon 1 "Iskra"**. This repository grew out of Iskra (Slackware, then CRUX
before that); the Slackware version is kept on the `slackware` branch.

## What it is made of

| Part | What |
|---|---|
| Base | CRUX 3.8: pkgutils, ports, BSD-style init, no systemd |
| Packages | **Metamelayer**, Avalon's package manager, over prt-get and pkgutils (to come) |
| Compositor | **MangoWC** (Wayland, dwl-based): tags, a Niri-style scroller, blur via scenefx |
| Shell | **The Garden System**, written in Quickshell: bar, launcher, notifications, lock, login, Command Mode (to come) |
| Terminal | kitty, which shows Pasha as a picture in fastfetch |
| Login | greetd, with the Garden System's own login screen (in cage) |
| Assistant | **Neredy**, local AI on llama.cpp; it also hosts the Russian tutor (to come) |
| Settings | **Avalon Control**, GTK4 (to come) |

No Flatpak: everything is a native package.

## This repository

| Folder | What |
|---|---|
| `ports/` | Avalon's CRUX ports collection: what CRUX doesn't have (Mango, scenefx, Quickshell, kitty, cage, cJSON, CLI11) |
| `desktop/` | The Garden System's settings and tools, as they're installed (`etc/`, `usr/`) |
| `desktop/etc/xdg/quickshell/garden/` | The Garden System shell: bar, launcher, notifications, lock, power menu, key reference, Neredy |
| `desktop/usr/share/garden/greeter.qml` | The login screen (greetd) |
| `branding/` | Pasha and the artwork; `build/render-garden.py` renders the wallpaper as a small PlayStation-style 3D scene |
| `russian/` | The Russian learning kit, to become Neredy's tutor |

## Installing

### The disc

Build it on your own machine (Arch, or Arch on WSL), as root, from this repo:

    sudo build/make-iso

It downloads the official CRUX 3.8 ISO (checking its checksum), makes a CRUX build system from
its packages in `/var/tmp/avalon-iso`, brings CRUX's ports up to date there and compiles what
Avalon needs that the ISO lacks: Avalon's own kernel (Linux 7.3, for the Panther Lake graphics;
CRUX 3.8's ISO has 6.12), Mango, Quickshell, greetd, PipeWire and the rest. Every build is shown.
If one fails, run the same command again and it carries on. The result is
`avalon-1-iskra.iso`, with Neredy's Russian voice on it (`NEREDY_MODEL=small` adds her model too).

### On the laptop

1. Write the ISO to a USB stick, boot it, log in as root.
2. Partition and mount (the EFI partition too), for example:

       mkfs.fat -F32 /dev/nvme0n1p1 && mkfs.ext4 /dev/nvme0n1p2
       mount /dev/nvme0n1p2 /mnt && mkdir -p /mnt/boot/efi && mount /dev/nvme0n1p1 /mnt/boot/efi

3. Install:

       /media/avalon-install YOURNAME

   Nothing is downloaded or compiled: it installs CRUX's core and every Avalon package from the
   disc, writes `/etc/fstab`, creates your user, asks for your and root's passwords, and installs
   GRUB. Then `reboot` into the Garden System.

### On an existing CRUX install instead

    git clone https://github.com/factionparadox/Iskra /usr/ports/avalon
    /usr/ports/avalon/avalon-setup YOURNAME

This builds everything on the laptop itself with prt-get.

## Status

The ports are first drafts, not yet built: they get tested on the laptop, on a fresh CRUX install.
Keys are in `desktop/etc/mango/config.conf` (Super+/ will show them once the shell is in).
