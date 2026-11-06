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
| Packages | **Metamelayer**, Avalon's package manager, over prt-get and pkgutils, with your own signing key |
| Escape hatch | Gentoo with **Portage**, in its own root: `sudo metamelayer gentoo` |
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
current firmware, a Gentoo base system with Portage and Neredy's Russian voice, and writes
`avalon-1-iskra.iso`. `NEREDY_MODEL=small` puts Neredy's model on it too.

### On the laptop

1. Write the ISO to a USB stick (Rufus: DD image mode) and boot it (F12 at the Framework logo).
2. The installer starts by itself, in large type, as menus like CRUX's own setup. It asks your
   username, your password and root's, which disk (from a list), and whether to erase it (yes or
   no). Then it installs from the stick, with no internet and nothing compiled, showing its
   progress: CRUX's core, Gentoo's kernel and firmware, Gentoo with Portage, Avalon's ports,
   fstab, you, and GRUB with the Garden's boot screen.
3. Restart (it offers to), taking the stick out. **The first start builds Avalon on the laptop**:
   it lists the Wi-Fi networks it can see and asks for the password (or use a cable), then builds
   Avalon with the build scrolling past, and restarts into the Garden System. If a build fails it
   offers to try again (carrying on), show the log, or open a shell; `avalon-firstboot` carries
   on later too. Once Avalon is built, NetworkManager looks after the network (`nmtui`, or
   Avalon Control), with your Wi-Fi already saved.

To lay the disk out yourself, open a shell on the stick (Alt+F2, log in as root), partition and
mount it under `/mnt` (EFI at `/mnt/boot/efi`), and run `/media/avalon-install`: it uses that.

### Portage, the escape hatch

Gentoo lives in its own root, `/var/lib/gentoo`, so Portage and CRUX never overwrite each other.
How it works, what it shares with Avalon and how to use it in an emergency:
[docs/escape-hatch.md](docs/escape-hatch.md).

    sudo metamelayer gentoo                 # a shell in Gentoo
    sudo metamelayer gentoo emerge PACKAGE  # Gentoo's prebuilt packages where there are any
    sudo metamelayer gentoo run PROGRAM     # run a Gentoo program on Avalon's desktop

### On an existing CRUX install instead

    git clone https://github.com/factionparadox/Iskra /usr/ports/avalon
    /usr/ports/avalon/avalon-setup YOURNAME

## Status

The install disc builds (`build/make-iso`, 3.1 GB). Nothing has run on the laptop yet: the
installer, the first-boot build, the ports and the Garden System get their first real test there.
Keys are in `desktop/etc/mango/config.conf`; Super+/ shows them on the desktop.

CRUX's own handbook is on the disc as `/media/crux/handbook.txt`; this file is there as
`/media/AVALON-README.txt`, with the technical documents in `/media/avalon-docs/`.
