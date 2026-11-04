# Locale, keyboard, console and time zone

## Locales (language and formats)
Slackware's glibc comes with its locales ready-made (the glibc-i18n package): there is nothing to
generate.
  locale                                        what this shell uses
  locale -a                                     what is available
The language itself is the LANG variable: en_GB.UTF-8 (English, British spelling, dates and
paper size). The installer set it in /etc/profile.d/lang.sh (export LANG=en_GB.UTF-8), which
every login shell reads.

One part can differ, for just your account, in ~/.bash_profile:
  export LC_TIME=ru_RU.UTF-8                    Russian dates, English everything else
  export LANG=ru_RU.UTF-8                       Russian throughout, where programs have it
For every user, the same lines in /etc/profile.d/lang.sh. An upgrade of the package that owns
it puts its own copy beside yours as lang.sh.new (see: pkgtools).

## The keyboard
X: /etc/X11/xorg.conf.d/30-iskra.conf
  Option "XkbLayout" "gb,ru"   Option "XkbVariant" ",phonetic"
  Option "XkbOptions" "grp:alt_shift_toggle"
English (UK) and Russian phonetic, Alt+Shift to switch. setxkbmap -query shows what X uses;
try another layout for this session with
  setxkbmap -layout gb,ru -variant ,phonetic -option grp:alt_shift_toggle
and make it permanent in that file (it belongs to iskra-desktop: an update keeps your version
and puts the new one beside it as 30-iskra.conf.new).
The text console: /etc/rc.d/rc.keymap, which the installer wrote and rc.M runs at boot
(loadkeys uk.map; the maps are in /usr/share/kbd/keymaps). GRUB uses the firmware's US layout.

## The console
/etc/rc.d/rc.font sets the console font at boot from /etc/default/rc.font (FONT=, or
FONT=auto and a list to choose from by the screen's width). setfont tries another for the
moment, from /usr/share/kbd/consolefonts (Cyrillic ones included).

## Time zone
/etc/localtime is a link to the zone in /usr/share/zoneinfo ("Europe/London" unless you chose
another). Change it with  sudo timeconfig,  or by hand:
  sudo ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
For one shell:  TZ=Europe/Moscow date
The hardware clock keeps UTC (/etc/hardwareclock). The night light (iskra-nightlight) works out
sunset from the time zone.

See also: time, system-files ; man locale ; man setxkbmap ; man loadkeys ; man setfont ;
man timeconfig
