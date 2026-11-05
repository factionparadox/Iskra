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
| `branding/` | Pasha and the artwork |
| `russian/` | The Russian learning kit, to become Neredy's tutor |

## Status

The ports are first drafts, not yet built: they get tested on the laptop, on a fresh CRUX install.
Keys are in `desktop/etc/mango/config.conf` (Super+/ will show them once the shell is in).
