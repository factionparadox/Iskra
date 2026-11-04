# The desktop: X11, the session, the bar, the menus

ly is the login screen: a text box on tty1. /etc/inittab runs it on tty1 instead of the usual
login prompt (through agetty and /usr/lib/iskra/login, which falls back to a text login if ly
won't start); its settings are /etc/ly/config.ini, which the installer set (Iskra's black,
white and red, and auto_login_user if you chose automatic login). ly starts X and
/usr/bin/iskra-session: a short script, one line per piece. Read it: it is the desktop.

    pipewire, wireplumber, pipewire-pulse   sound (iskra-learn learn sound)
    xrdb        fonts, DPI and terminal colours (/etc/iskra/Xresources, then ~/.Xresources)
    xss-lock    locks the screen with slock when the screen saver starts and on Super+x
    dunst       notifications
    udiskie     mounts USB drives as they are plugged in
    xbanish     hides the pointer while you type
    iskra-battery  low-battery warnings and hibernation
    clipmenud   remembers what you copy (Super+v picks it again)
    gnome-keyring    the Secret Service, where programs keep passwords
    iskra-nightlight  redshift: a warmer screen after sunset, worked out from your timezone
    polybar     the bar: workstation, window title, layout, volume, light, Wi-Fi, battery, clock
    ratpoison   the window manager (see: iskra-learn learn ratpoison)
Add your own programs in ~/.config/iskra/autostart (an executable script).

## X-терминал, the terminal
Iskra's own: st (suckless), built from st-flexipatch with scrollback and clickable links, in
Plan 9's look: acme's pale yellow and Go Mono. Ctrl+Super+t opens one.
- Select text and it is copied; Ctrl+Shift+v pastes. Shift+PgUp/PgDn or the wheel scroll back.
- Double-click a word, then right-click: the Plan 9 plumber opens it (a file in acme, a URL in
  Firefox, ls(1) as a man page).
- Ctrl+Shift+PgUp/PgDn: bigger and smaller text.
Its settings are C source (config.h in Iskra's x-terminal SlackBuild), compiled in;
iskra-learn wiki slackbuilds shows how to change and rebuild it. iskra-term is the script every menu uses to
open it.

## Menus
Ctrl+Super+Space is iskra-menu: dmenu lists of "label, command". Super+Space is dmenu_run: type
any program's name. Entries whose program is not installed are hidden. Wi-Fi opens
networkmanager_dmenu, Bluetooth bluetuith, the VPN the Proton VPN app, and the System menu has
framework_tool's switches (touchscreen, keyboard light, click force). To change a menu, copy
/usr/bin/iskra-menu to ~/.local/bin and edit your copy.

## The keyboard
English (UK) and Russian phonetic, Alt+Shift to switch, in /etc/X11/xorg.conf.d/30-iskra.conf.
The text console uses the UK keymap (/etc/rc.d/rc.keymap). The bar shows EN or RU.

## Change things
    ~/.config/polybar/config.ini      then: pkill polybar; polybar iskra &
    ~/.Xresources                     then: xrdb -merge ~/.Xresources
    /var/log/Xorg.0.log               the X server's log
    ~/.local/share/xorg-session.log   the session's output, when started with startx
The files in /etc/iskra belong to the iskra-desktop package: you can edit them, and an
update then leaves your version in place and puts the new one beside it as NAME.new
(iskra-learn wiki pkgtools). Your own copies in your home folder are simpler.

References: man startx ; man polybar ; man dmenu ; man dunst ; man slock
