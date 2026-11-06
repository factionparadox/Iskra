# Avalon

Avalon is a Linux system for the Framework Laptop 13 Pro, built on **CRUX**: a minimal base you
compile into your own, with the **Garden System** on top, a desktop whose look comes from the
late-1990s PlayStation game *Pixygarden* (an original design in its spirit, not the game's art).
Its keeper is **Pasha**, a little arctic wolf pup.

The first release is **Avalon 1 "Iskra"**.
## What it is made of

| Part | What |
|---|---|
| Base | CRUX 3.8: pkgutils, ports, BSD-style init, no systemd |
| Kernel | Gentoo's prebuilt distribution kernel (7.3), for the Panther Lake graphics, NPU and Wi-Fi 7 |
| Packages | **Metamelayer**, Avalon's package manager, over prt-get and pkgutils, with your own signing key. Like NuTyX's CARDS, it reads the libraries each program loads: it says when a Pkgfile misses a dependency, and rebuilds whatever an update broke (`metamelayer deps`, `check`, `fix`) |
| Snapshots | Btrfs: one is taken by itself before every install, upgrade and removal, and the boot menu's **Avalon as it was** starts any of them. `metamelayer rollback NAME` makes one the system again (your files and logs stay as they are), and can itself be undone |
| Flatpak | Only for apps published nowhere else, such as Sober: `metamelayer flatpak install org.vinegarhq.Sober` |
| Compositor | **MangoWC** (Wayland, dwl-based): tags, a Niri-style scroller, blur via scenefx |
| Shell | **The Garden System**, in Quickshell: HUD, star system, launcher, Command Mode, notifications, lock, login |
| Terminal | kitty, which shows Pasha as a picture in fastfetch |
| Login | greetd, with the Garden System's own login screen (in cage) |
| Assistant | **Neredy**, local AI on llama.cpp (Vulkan), with a Russian tutor mode and a Russian voice (Piper) |
| Settings | **Avalon Control**, GTK4 (Super+,): [docs/avalon-control.md](docs/avalon-control.md) |
| Commands | **Command Mode** (Super+;): run the Garden by typing, [docs/command-mode.md](docs/command-mode.md) |

No Flatpak: everything is a native package.

## This repository

| Folder | What |
|---|---|
| `ports/` | Avalon's CRUX ports: what CRUX doesn't have (Mango, scenefx, Quickshell, kitty, cage, cJSON, CLI11, llama.cpp, Piper, Gentoo's kernel) and `avalon`, which pulls everything in |
| `build/make-iso`, `build/iso/` | The install disc: how it's made, its installer and the first-boot build |
| `avalon-setup` | Turns CRUX into Avalon (the first boot runs it; it works on any CRUX 3.8 too) |
| `desktop/` | The Garden System's settings and tools, as they're installed (`etc/`, `usr/`) |
| `desktop/etc/xdg/quickshell/garden/` | The Garden System shell: bar, launcher, notifications, lock, power menu, key reference, Neredy |
| `desktop/usr/share/garden/greeter.qml` | The login screen (greetd) |
| `branding/` | Pasha and the artwork; `build/render-garden.py` renders the wallpaper as a small PlayStation-style 3D scene |
| `russian/` | The Russian learning kit, to become Neredy's tutor |

## Installing

### The disc

Make it on your own machine (Arch, or Arch on WSL), as root, from this repo:

    sudo build/make-iso

Nothing is compiled: it downloads and checks the official CRUX 3.8 ISO, Gentoo's prebuilt
distribution kernel (Linux 7.3, which knows the Panther Lake graphics; CRUX 3.8's ISO has 6.12),
current firmware and Neredy's Russian voice, and writes
`avalon-1-iskra.iso`. `NEREDY_MODEL=small` puts Neredy's model on it too.

### On the laptop

1. Write the ISO to a USB stick (Rufus: DD image mode) and boot it (F12 at the Framework logo).
2. The installer starts by itself, in large type, as menus like CRUX's own setup. It asks your
   username, your password and root's, which disk (from a list), and whether to erase it (yes or
   no). Then it installs from the stick, with no internet and nothing compiled, showing its
   progress: the disk (Btrfs, with the system, your files, the logs and the snapshots each in a
   subvolume of their own), CRUX's core, Gentoo's prebuilt kernel and firmware, Avalon's ports,
   fstab, you, and GRUB with the Garden's boot screen.
3. Restart (it offers to), taking the stick out. **The first start builds Avalon on the laptop**:
   it lists the Wi-Fi networks it can see and asks for the password (or use a cable), then builds
   Avalon with the build scrolling past, and restarts into the Garden System. It takes a
   snapshot just before the build ("fresh install") and one when it's done ("avalon built"). If a build fails it
   offers to try again (carrying on), show the log, or open a shell; `avalon-firstboot` carries
   on later too. Once Avalon is built, NetworkManager looks after the network (`nmtui`, or
   Avalon Control), with your Wi-Fi already saved.

To lay the disk out yourself, open a shell on the stick (Alt+F2, log in as root), partition and
mount it under `/mnt` (EFI at `/mnt/boot/efi`), and run `/media/avalon-install`: it uses that.
Snapshots need the same layout as the installer's: Btrfs, with subvolumes `@` at `/`, `@home`,
`@log` at `/var/log` and `@snapshots` at `/.snapshots`. On any other layout Avalon works the
same, just without snapshots.

### Snapshots

    metamelayer snapshots              what there is, newest first
    sudo metamelayer snapshot WHY      one now, kept until you forget it
    sudo metamelayer rollback NAME     the system as it was in NAME, from the next start
    sudo metamelayer forget NAME       delete one

The automatic ones (before each install, upgrade and removal) keep the newest 10. To try a
snapshot without committing, pick it under **Avalon as it was** in the boot menu; to keep it,
`sudo metamelayer rollback NAME` from there.

### Something CRUX doesn't have

`sudo metamelayer new NAME` starts a port for it in Avalon's ports
(`/usr/ports/avalon/ports/NAME/Pkgfile`), filled in from Arch's package where there is one: the
description, homepage, version, dependencies as CRUX ports, and a `build()` for its build system.
Add the source address, then `sudo metamelayer sign NAME && sudo metamelayer install NAME`.

To keep a package where it is through upgrades: `sudo metamelayer hold NAME` (`unhold` lets it
go). Builds go through ccache, so rebuilding something already built once is mostly cached
(`metamelayer cache` shows how much). Every build keeps its log: `metamelayer log NAME`.
For apps only published as Flatpaks (Sober, for one): `metamelayer flatpak install APP`.

### On an existing CRUX install instead

    git clone https://github.com/factionparadox/Iskra /usr/ports/avalon
    /usr/ports/avalon/avalon-setup YOURNAME

## Status

The install disc builds (`build/make-iso`, 3.1 GB). Nothing has run on the laptop yet: the
installer, the first-boot build, the ports and the Garden System get their first real test there.
Keys are in `desktop/etc/mango/config.conf`; Super+/ shows them on the desktop.

CRUX's own handbook is on the disc as `/media/crux/handbook.txt`; this file is there as
`/media/AVALON-README.txt`, with the technical documents in `/media/avalon-docs/`.
