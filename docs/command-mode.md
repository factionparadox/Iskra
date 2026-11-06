# Command Mode

**Super+;** opens a command line in the Garden System, in the game's navy dialogue box. Type a
command and the ones that fit are listed under it, the chosen one on the violet bar.

| Key | Does |
|---|---|
| Up / Down | choose among the listed commands |
| Tab | fill in the chosen command's name |
| Enter (or "run") | run the line |
| Up / Down, with the line empty | go back through what you ran before |
| Escape (or "close") | close |

A short start works when only one command fits it: `vol 40` is `volume 40`.

| Command | What it does |
|---|---|
| `visit 3`, `visit soyuz` | go to a workstation (by number or by its planet's name) |
| `send 2` | move the focused window to a workstation |
| `open web` (discord, video, files, anime, vpn) or `open NAME` | start a program |
| `run COMMAND` | run a shell command |
| `term [COMMAND]` | open kitty, running the command if given |
| `volume 40` / `up` / `down` / `mute` | sound volume |
| `brightness 60` / `up` / `down` | screen brightness |
| `wifi on` / `off`, or `wifi` | Wi-Fi on or off, or the network page of Avalon Control |
| `bluetooth on` / `off`, or `bluetooth` | the same for Bluetooth |
| `night on` / `off` | warmer colours (wlsunset) |
| `ask QUESTION` | open Neredy and ask her |
| `say ТЕКСТ` | Neredy reads Russian text aloud |
| `settings [PAGE]` | Avalon Control, at a page |
| `update` | `sudo metamelayer upgrade`, in a terminal |
| `lock`, `suspend`, `restart`, `off` | the session |
| `shot` | screenshot of an area, to edit and save |
| `reload` | restart the Garden System |
| `help` | list every command |

`volume up`/`down` and `brightness up`/`down` keep the box open, so you can press Enter again.
Mistakes are shown in magenta inside the box, and it stays open.

To add a command, add an entry to `commands` in
`desktop/etc/xdg/quickshell/garden/modules/CommandMode.qml`: a name, what it takes, what it does,
and a `run` function given the words after the name.
