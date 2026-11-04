# rc: init and services

Slackware's init is SysVinit's /sbin/init, process 1, with BSD-style scripts: no folders full of
links, just a handful of shell scripts in /etc/rc.d that you can read in an afternoon. init
starts what /etc/inittab says, respawns the consoles, and runs the shutdown scripts. There is
no systemd.

## The scripts
  /etc/inittab         the runlevels: 1 single user, 3 multi-user (the default), 0 halt,
                       6 reboot (4 is a graphical login, which Iskra doesn't use: ly does it on
                       runlevel 3); rc.S at boot, rc.M for multi-user, the consoles
  /etc/rc.d/rc.S       boot: mounts /proc, /sys and /run, starts udev (eudev), turns on swap,
                       sets the clock from the hardware clock, checks and mounts the
                       filesystems in fstab, loads modules (rc.modules)
  /etc/rc.d/rc.M       multi-user: the hostname (/etc/HOSTNAME), the system log, D-Bus,
                       elogind, Bluetooth, NetworkManager, acpid, crond, the console keymap
                       (rc.keymap) and the rest, each only if its script is executable; then
                       /etc/rc.d/rc.local, last
  /etc/rc.d/rc.K       single-user mode: stops the services, leaves a root shell
  /etc/rc.d/rc.6       reboot and halt (rc.0 is a link to it): runs rc.local_shutdown, stops
                       the services, saves the clock and the random seed, unmounts everything
  /etc/rc.d/rc.local   your own commands, at the end of boot (Iskra's start here: below)
  /etc/rc.d/rc.local_shutdown   your own commands at shutdown, first
  /etc/rc.d/rc.modules.local    modprobe lines for modules that should always load

## Services
A service is a script /etc/rc.d/rc.NAME taking start, stop, restart and, usually, status. It
starts at boot if it is executable; that is the whole switch:
  ls -l /etc/rc.d                      what is installed, and what is on (the x in rwx)
  sudo chmod +x /etc/rc.d/rc.sshd      start it at every boot from now on
  sudo chmod -x /etc/rc.d/rc.sshd      don't start it at boot any more
  sudo /etc/rc.d/rc.NAME start ; stop ; restart ; status     now, until the next boot
rc.M knows Slackware's own services, and starts them in a sensible order. Anything else, Iskra's
included, is started from rc.local. Nothing restarts a service that dies; its status says so,
and start brings it back.

## Iskra's services: rc.iskra
/etc/rc.d/rc.iskra, from iskra-desktop, starts Iskra's own services: rc.local calls
/etc/rc.d/rc.iskra start at the end of boot, and rc.local_shutdown calls it with stop.
  firewall    /etc/rc.d/iskra-firewall: loads the nftables rules (see: network)
  tlp         /etc/rc.d/rc.tlp: battery tuning
  thermald    Intel's thermal daemon, in adaptive mode
  lpmd        intel_lpmd, Intel's low-power daemon for these hybrid chips
  chrony      /etc/rc.d/rc.chrony: the clock (see: time)
  tutor       /etc/rc.d/iskra-tutor: the Russian tutor's model (llama-server), once downloaded
  sudo /etc/rc.d/rc.iskra status       which of them run
Each one starts only if it's installed, and the ones with a script of their own only if that
script is executable: sudo chmod -x /etc/rc.d/rc.tlp keeps TLP from starting at the next boot.
The list is SERVICES= at the top of rc.iskra.

Slackware's own services Iskra relies on, started by rc.M: rc.syslog, rc.udev, rc.messagebus
(D-Bus), rc.elogind, rc.networkmanager, rc.bluetooth and rc.acpid (iskra-desktop makes those
three executable), rc.crond. polkit, upower and udisks have no script: D-Bus starts them
when something asks.

## A real service: the tutor
/etc/rc.d/iskra-tutor, shortened:

  PROG=/usr/bin/llama-server
  MODEL=/var/lib/iskra/russian/tutor/tutor.gguf
  PID=/run/iskra-tutor.pid
  LOG=/var/log/iskra-tutor.log
  running() { [ -f $PID ] && kill -0 "$(cat $PID)" 2>/dev/null; }
  case $1 in
  start)
  	[ -f $MODEL ] || exit 0
  	running && exit 0
  	setsid setpriv --reuid=nobody --regid=nogroup --clear-groups -- \
  		$PROG --model $MODEL ... >> $LOG 2>&1 < /dev/null &
  	echo $! > $PID ;;
  stop)    running && kill "$(cat $PID)" ; rm -f $PID ;;
  restart) $0 stop ; $0 start ;;
  status)  running && echo running || echo "not running" ;;
  esac

- setpriv runs the program as nobody, setsid in a session of its own, and & in the background;
  its process number goes in a pidfile, which is how stop and status find it again.
- start does nothing until the model exists, so the service can be in rc.iskra from the
  first boot.
- Its output goes to its own log, /var/log/iskra-tutor.log.
The same shape gives you a service of your own: copy it to /etc/rc.d/rc.NAME, change PROG and
its arguments, chmod +x it, and add two lines to rc.local and rc.local_shutdown:
  [ -x /etc/rc.d/rc.NAME ] && /etc/rc.d/rc.NAME start        (in rc.local)
  [ -x /etc/rc.d/rc.NAME ] && /etc/rc.d/rc.NAME stop         (in rc.local_shutdown)

## Shutting down
  sudo poweroff ; sudo reboot          (no password: /etc/sudoers.d/iskra)
  sudo shutdown -h now ; sudo telinit 1   halt ; single-user mode

## Services for your user
There are none at system level: programs that need your X session go in
~/.config/iskra/autostart, which iskra-session runs.

See also: system-files, logging, sleep ; man init ; man inittab ; man telinit ;
iskra-handbook (the chapter Booting)
