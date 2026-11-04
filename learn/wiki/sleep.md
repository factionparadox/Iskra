# Sleep, hibernation and the lid

Slackware has no systemd, but it does have elogind: the part of systemd that keeps track of who
is logged in, on its own. It makes your runtime folder at login and tells polkit which session
is yours. The lid and the power button Iskra handles with three plain pieces instead: acpid
catches the events, iskra-sleep acts on them, and sudo lets your session run it without a
password.

## iskra-sleep
Run as root (acpid runs it so; from your session it calls itself through sudo, which
/etc/sudoers.d/iskra allows without a password):
  iskra-sleep suspend      lock the screen, then echo mem > /sys/power/state
  iskra-sleep hibernate    lock, then echo disk > /sys/power/state
  iskra-sleep power        the power button: suspend
  iskra-sleep lid          the lid closed: if it is still closed, lock and suspend; on
                             battery, with hibernation possible, suspend with an RTC alarm
                             two hours ahead (rtcwake), and if the alarm is what woke it,
                             hibernate
Locking: for every X display it runs  xset s activate  as the display's owner, which makes
xss-lock start slock. Super+z, the power menu and iskra-battery (at 4 %) use this script. The
two hours are HOURS= at the top of /usr/bin/iskra-sleep; an update of iskra-desktop replaces
that file, so keep a note of any change you make there.

## acpid, and elogind told to leave the lid alone
/etc/rc.d/rc.acpid, started by rc.M (iskra-desktop makes it executable). acpid reads the
kernel's ACPI events and runs the action of every rule in /etc/acpi/events whose event=
matches. iskra-desktop installs two:
  /etc/acpi/events/iskra-lid      event=button[ /]lid.*      action=/usr/bin/iskra-sleep lid
  /etc/acpi/events/iskra-power    event=button[ /]power.*    action=/usr/bin/iskra-sleep power
  acpi_listen               watch the events as they happen (close the lid, press a key)
Slackware's own rule (default) still hands every event to /etc/acpi/acpi_handler.sh, whose
power button line would shut the laptop down; iskra-desktop turns that line into a no-op.
elogind could act on the same keys, so /etc/elogind/logind.conf.d/50-iskra.conf tells it not
to: HandlePowerKey=ignore, HandleLidSwitch=ignore (on battery, on the charger and docked).
Add a rule of your own (for the charger, say: event=ac_adapter.*), then
sudo /etc/rc.d/rc.acpid restart.

## Hibernation
Hibernation writes memory to swap and powers off; the next boot reads it back. It needs:
- a swap partition at least as big as the memory in use (the installer made it the size of
  the RAM; on a small disk there is none);
- resume=PARTUUID=... on the kernel command line (the installer added it to /etc/default/grub).
  The kernel reads the image back by itself: no initrd is needed (see: boot);
- Secure Boot off (the kernel refuses hibernation under lockdown).
iskra-sleep checks the first two (grep resume= /proc/cmdline, a partition in /proc/swaps)
and refuses to hibernate without them. Test: iskra-sleep hibernate. If it comes back to a
fresh boot instead, check  cat /proc/cmdline  and  sudo dmesg | grep -i -e resume -e hibernat.

## Suspend modes
  cat /sys/power/mem_sleep          [s2idle] is normal on this laptop (S0ix)
  iskra-sleepcheck                suspends for a minute and reports the time in S0ix
                                    (see: framework)

## What elogind does besides
- XDG_RUNTIME_DIR (/run/user/UID), where PipeWire and others keep their sockets: made at
  login (pam_elogind) and removed at logout.
- polkit asks it which session is active, so "the user at the keyboard" rules work for udisks
  and NetworkManager.
- loginctl: list-sessions, and suspend or hibernate too (without iskra-sleep's checks).
- Idle actions are not its job here: xset's screen saver and DPMS times are (iskra-session and
  iskra-battery).

See also: power (iskra-learn learn power), boot, users ; man logind.conf ; man acpid ;
man rtcwake ; https://docs.kernel.org/admin-guide/pm/sleep-states.html
