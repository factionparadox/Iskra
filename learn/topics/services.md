# Services: Slackware's rc scripts

Slackware's init is SysVinit's init, process 1, with BSD-style scripts: no folders of links,
only a few shell scripts in /etc/rc.d. /etc/inittab says what init runs: rc.S at boot (udev,
swap, the filesystems), then rc.M for multi-user (runlevel 3), which starts each of
Slackware's services whose script is executable, then rc.local last. At shutdown rc.6 (rc.0 is
a link to it) runs rc.local_shutdown, then stops everything.

A service is a script /etc/rc.d/rc.NAME that takes start, stop, restart and (usually) status.
Whether it starts at boot is whether it is executable:
    ls -l /etc/rc.d                          the x in rwx: those start at boot
    sudo /etc/rc.d/rc.bluetooth status       one service (the scripts are short: read them)
    sudo /etc/rc.d/rc.bluetooth restart      also: start, stop
    sudo chmod -x /etc/rc.d/rc.bluetooth     don't start it at boot any more (+x: do)
Changes made with the script itself last until the next boot.

## Iskra's services: rc.iskra
rc.local runs /etc/rc.d/rc.iskra start at the end of boot (and rc.local_shutdown runs it with
stop). It starts, in order: iskra-firewall (nftables) · TLP (rc.tlp, battery tuning) ·
thermald (heat) · intel_lpmd (Intel's low-power daemon) · chrony (rc.chrony, the clock) ·
iskra-tutor (the Russian tutor, once its model is downloaded). Each only if it's installed, and
the ones with a script of their own only if that script is executable.
    sudo /etc/rc.d/rc.iskra status

Slackware's own, from rc.M: the system log (rc.syslog), udev, D-Bus (rc.messagebus), elogind
(logins and sessions), NetworkManager, Bluetooth, acpid, crond. inittab starts ly on tty1 and
text logins on the other consoles. Some pieces are not services at all: polkit, upower and
udisks start when D-Bus asks for them; slock is a setuid program; gnome-keyring and PipeWire
run inside your session.

## Shutting down
    sudo poweroff ; sudo reboot            no password needed (/etc/sudoers.d/iskra)

References: man init ; man inittab ; iskra-handbook (Booting) ; iskra-learn wiki rc
