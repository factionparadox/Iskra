# Logging

Slackware has no journal. Messages are plain text: programs send them to syslog, the system log
daemon (sysklogd, started by rc.M through /etc/rc.d/rc.syslog) writes them into files in
/var/log, and you read them with less, tail and grep.

## The system log
/etc/syslog.conf decides which messages go where. The ones to know:
  /var/log/messages          the ordinary messages: daemons, the kernel, what is going on
  /var/log/syslog            warnings and errors (start here when something is wrong)
  /var/log/secure            logins, su and sudo
  /var/log/cron              crond's jobs
Reading them needs root:
  sudo tail -f /var/log/messages /var/log/syslog    follow both live (Ctrl+C stops)
  sudo grep -i error /var/log/syslog
  sudo less +G /var/log/messages               (the menu: System -> The log)
  ls /var/log                                  what else is there
Old logs are rotated by logrotate, run daily by crond (/etc/cron.daily/logrotate), so the
disk does not fill.

## A service's own log
Services started from /etc/rc.d log through syslog unless their script sends the output
elsewhere; Iskra's tutor writes /var/log/iskra-tutor.log. When a service fails silently,
run its script by hand to see what it says:
  sudo /etc/rc.d/rc.NAME status
  sudo sh -x /etc/rc.d/rc.NAME start           every command the script runs

## Packages and the install
  /var/log/slpkg/history.log        every install, upgrade and removal (sparkpkg history)
  /var/log/slpkg/process.log        the output of each build and installation
  /var/log/pkgtools/removed_packages   the file lists of packages removed or replaced
  /var/log/iskra-install.log        every command the installer ran, with its output

## The kernel
  sudo dmesg                 the kernel's ring buffer since boot
  sudo dmesg -w              follow
  sudo dmesg --level=err,warn

## Other logs
  /var/log/Xorg.0.log               the X server (or ~/.local/share/xorg/Xorg.0.log)
  ~/.local/share/xorg-session.log   the session's output, when started with startx

See also: rc ; man syslog.conf ; man syslogd ; man dmesg
