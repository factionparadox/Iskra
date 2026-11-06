# Avalon

Avalon is a Linux system for the Framework Laptop 13 Pro: an **image-based** Fedora system
(built on Universal Blue) with the **Garden System** on top, a desktop whose look comes from the
late-1990s PlayStation game *Pixygarden* (an original design in its spirit, not the game's art).
Its keeper is **Pasha**, a little arctic wolf pup.

The first release is **Avalon 1 "Iskra"**.

## What it is made of

| Part | What |
|---|---|
| Base | Universal Blue's `base-main` (Fedora 44, image-based, no desktop of its own): the system is read-only, each update is a whole new image, and the one before stays a restart away |
| Packages | **Metamelayer**: builds Avalon's image on the laptop and switches to it; rollback; Flatpaks; extras on top; boxes |
| Apps | Native Fedora packages for everything; Flatpak (Flathub) only for things published nowhere else, such as Sober |
| Escape hatch | Gentoo with **Portage**, in a box (distrobox): `metamelayer gentoo` |
| Compositor | **MangoWC** (Wayland, dwl-based): tags, a Niri-style scroller, blur via scenefx |
| Shell | **The Garden System**, in Quickshell: HUD, star system, launcher, Command Mode, notifications, lock, login |
| Terminal | kitty, which shows Pasha as a picture in fastfetch |
| Login | greetd, with the Garden System's own login screen (in cage) |
| Assistant | **Neredy**, local AI on llama.cpp (Vulkan), with a Russian tutor mode and a Russian voice (Piper) |
| Settings | **Avalon Control**, GTK4 (Super+,): [docs/avalon-control.md](docs/avalon-control.md) |
| Commands | **Command Mode** (Super+;): run the Garden by typing, [docs/command-mode.md](docs/command-mode.md) |

## This repository

| Path | What |
|---|---|
| `Containerfile` | The Avalon image: Universal Blue's base, then everything below |
| `build/image/packages` | Avalon's packages (Fedora, and Mango from its COPR): add what you want for good here |
| `build/image/build.sh` | Installs them, llama.cpp and Piper (pinned, checked), names the system, switches services on |
| `build/make-image`, `build/make-iso` | Build the image, and an installer USB from it, on your own machine |
| `desktop/` | The Garden System, Avalon's commands and settings, exactly as they land in the image (`etc/`, `usr/`) |
| `desktop/etc/xdg/quickshell/garden/` | The Garden System shell |
| `branding/`, `build/render-garden.py` | Pasha and the artwork; the wallpaper is a small PlayStation-style 3D scene |
| `russian/` | The Russian learning kit, to become Neredy's tutor |

## Installing

### The installer USB

On your own machine (Arch, or Arch on WSL), as root, from this repository:

    sudo build/make-image && sudo build/make-iso

`make-image` pulls Universal Blue's base and builds Avalon on it with podman (nothing is compiled:
Fedora's packages, Mango from its COPR, llama.cpp's and Piper's own releases, each checked).
`make-iso` turns that image into `avalon-1-iskra.iso` with Fedora's own installer.

### On the laptop

1. Write the ISO to a USB stick (Rufus: DD image mode) and boot it (F12 at the Framework logo).
2. Fedora's installer (Anaconda) starts by itself, graphical, with British English, the UK
   keyboard and London time already set. Choose the disk and make your user (tick "administrator"),
   then install.
3. Restart into the Garden System's login screen.

Then, once:

    neredy setup small      # Neredy's model and voice (or: large, for the best Russian tutor)

### Already on Fedora Atomic or Universal Blue?

Switch to Avalon without reinstalling, building the image on the laptop itself:

    git clone https://github.com/factionparadox/Iskra /tmp/avalon && sudo /tmp/avalon/desktop/usr/bin/metamelayer update

## Keeping it up to date

    sudo metamelayer update      # fetch Avalon, build the new image here, switch at the next restart
    sudo metamelayer rollback    # back to the previous one, at the next restart

Avalon Control's Updates page and `update` in Command Mode do the same. Metamelayer keeps its
copy of this repository in `/var/lib/avalon/repo`; point `AVALON_UPSTREAM` at your own fork to
build from that instead.

### Apps

    metamelayer flatpak install org.vinegarhq.Sober   # Flathub, for things only published there
    sudo metamelayer add htop                         # a Fedora package on top (next restart)
    metamelayer box                                   # a mutable Fedora box, for trying things
    metamelayer gentoo                                # Gentoo with Portage, in a box

What you want for good goes in `build/image/packages`, then `sudo metamelayer update`.
The escape hatch is explained in [docs/escape-hatch.md](docs/escape-hatch.md).

## Status

Untested on the laptop: the image, the installer USB and the Garden System get their first real
test there. The CRUX version this grew from is in the history; a Guix draft is on the
`guix-draft` branch; the Slackware version (Iskra) is on the `slackware` branch.
Keys are in `desktop/etc/mango/config.conf`; Super+/ shows them on the desktop.
