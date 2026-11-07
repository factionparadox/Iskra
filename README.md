# Avalon

Avalon is a Linux system for the Framework Laptop 13 Pro, built on **Slackware -current**, with the
**Garden System** on top: a desktop whose look comes from the late-1990s PlayStation game
*Pixygarden* (an original design in its spirit, not the game's art). Its keeper is **Pasha**, a
little arctic wolf pup.

The first release is **Avalon 1 "Iskra"**.

## What it is made of

| Part | What |
|---|---|
| Base | Slackware -current: Slackware's own ready-made packages, BSD-style init, no systemd |
| Kernel | Slackware's (7.3), with NVMe, Btrfs and Intel VMD built in, and Panther Lake's graphics (xe) and Wi-Fi 7 (iwlmld) |
| Packages | **Metamelayer**, over slpkg: a ready-made package wherever one exists (Slackware's, then AlienBOB's and conraid's), otherwise built from Ponce's SlackBuilds, dependencies resolved. `metamelayer check` finds anything an upgrade left without its libraries |
| Snapshots | Btrfs: one is taken by itself before every install, upgrade and removal, and the boot menu's **Avalon as it was** starts any of them. `metamelayer rollback NAME` makes one the system again (your files and logs stay as they are), and can itself be undone |
| Compositor | **MangoWC** (Wayland, dwl-based): tags, a Niri-style scroller, blur via scenefx |
| Shell | **The Garden System**, in Quickshell: HUD, star system, launcher, Command Mode, notifications, lock, login |
| Terminal | kitty, which shows Pasha as a picture in fastfetch |
| Login | greetd (runlevel 4), with the Garden System's own login screen (in cage) |
| Assistant | **Neredy**, local AI on llama.cpp (Vulkan), with a Russian tutor mode and a Russian voice (Piper) |
| Settings | **Avalon Control**, GTK4 (Super+,): [docs/avalon-control.md](docs/avalon-control.md) |
| Commands | **Command Mode** (Super+;): run the Garden by typing, [docs/command-mode.md](docs/command-mode.md) |

## This repository

| Folder | What |
|---|---|
| `packages/` | Avalon's SlackBuilds for what Slackware lacks (Mango, scenefx, Quickshell, cage, kitty, llama.cpp, Piper, avalon-desktop) and `packages/LIST`, which also names the Ponce SlackBuilds it uses (greetd, slpkg and some small tools) |
| `build/` | How the stick is made: `slackware-root`, `build-packages`, `build-iso` (with liveslak), and `iso/` (its installer and live-session settings) |
| `desktop/` | The Garden System's settings and Avalon's tools, as they're installed (`etc/`, `usr/`): the `avalon-desktop` package |
| `desktop/etc/xdg/quickshell/garden/` | The Garden System shell: bar, launcher, notifications, lock, power menu, key reference, Neredy |
| `desktop/usr/share/garden/greeter.qml` | The login screen (greetd) |
| `branding/` | Pasha and the artwork; `build/render-garden.py` renders the wallpaper as a small PlayStation-style 3D scene |
| `russian/` | The Russian learning kit, to become Neredy's tutor |

## Installing

### The stick

Made on your own machine (Arch on WSL is fine), with one command:

    cd ~/avalon && git pull && sudo build/build-iso

It downloads Slackware -current's packages (about 3.6 GB the first time; kept for next time, every
one checked against Slackware's signature), builds Avalon's own packages in a clean Slackware
system (the first time takes a while; after that only what changed), and makes
`out/avalon-1-x86_64.iso`. If any package won't build, it stops there, before a stick exists.
Write the ISO to a USB stick with Rufus (DD mode) or Fedora Media Writer.

### On the laptop

Secure Boot off; start from the stick in UEFI mode. The boot menu says **Install Avalon**, and the
installer starts by itself in large type. It asks five things: your username, your password,
root's password, the disk (from a list), and yes or no to erasing it. Then, with no internet and
nothing compiled, it:

1. lays the disk out: 1 GiB EFI, and Btrfs with the system, your files, the logs and the snapshots
   each in a subvolume of their own;
2. copies the system across from the stick;
3. sets it up: London time, British English and keyboard, you, the Garden's login screen,
   NetworkManager and Bluetooth, GRUB with the Garden's boot menu, and a first snapshot.

Then it restarts into the Garden's login screen. Wi-Fi: Super+; then `wifi`.

### Snapshots

    metamelayer snapshots              what there is, newest first
    sudo metamelayer snapshot WHY      one now, kept until you forget it
    sudo metamelayer rollback NAME     the system as it was in NAME, from the next start
    sudo metamelayer forget NAME       delete one

The automatic ones (before each install, upgrade and removal) keep the newest 10. To try a snapshot
without committing, pick it under **Avalon as it was** in the boot menu.

### Software

    metamelayer search WORDS          every repository at once
    sudo metamelayer install NAME     ready-made if anyone has it; otherwise built here from source
    sudo metamelayer upgrade          everything up to date (asks before it changes anything)

## Status

Avalon 1 is being tested end to end (the stick built, booted, installed and started under UEFI)
before release.
