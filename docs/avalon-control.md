# Avalon Control

Avalon's settings, a GTK4 program in the Garden System's colours. **Super+,** opens it, as does
`avalon-control [PAGE]` or `settings PAGE` in Command Mode.

It uses the same tools you would by hand, so nothing is hidden and nothing is locked away:

| Page | What it changes, and how |
|---|---|
| Appearance | wallpaper (`~/.config/avalon/wallpaper`, a link to your picture); Mango's blur, shadows, dimming, animations, gaps, border |
| Display | brightness (`brightnessctl`), night light (`wlsunset`) |
| Sound | speaker and microphone volume and mute (`wpctl`) |
| Network | Wi-Fi on/off, networks, joining one (`nmcli`) |
| Bluetooth | on/off, looking for devices, pairing, connecting, forgetting (`bluetoothctl`) |
| Power | battery charge and health; the charge limit (`sudo avalon-power charge-limit N`, kept for every boot); lock, suspend, restart, off |
| Keyboard | layouts (Alt+Shift switches), key repeat, touchpad (Mango's settings) |
| Neredy | her model (small or large), her voice, `neredy check` |
| Updates | `metamelayer upgrade` and `sync`, in a terminal; what's newer (`prt-get diff`) |
| Escape hatch | Gentoo's state; install or run a Gentoo package; shell, sync, update, unmount |
| About | the system, kernel, processor, graphics, memory, disk |

**Mango's settings.** Your changes go in `~/.config/mango/config.conf`: a copy of Avalon's
`/etc/mango/config.conf` with your changes, which Mango reads instead. Mango reloads at once.
"Reset" on the Appearance page deletes your copy, so you're back to Avalon's defaults (and get any
improvements to them that came with updates).

Long jobs (updates, downloading Neredy's model, Gentoo) open in kitty, so you can watch them and
answer `sudo`.
