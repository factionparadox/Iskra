# Time and scheduled jobs

## The clock: chrony
chronyd keeps the clock right over the network, with the servers in /etc/chrony.conf. It copes
well with a laptop that sleeps and changes networks. /etc/rc.d/rc.chrony runs it, and rc.iskra
starts that at boot (see: rc). Slackware's own ntpd (rc.ntpd) stays off: one clock-setter is
enough.
  sudo /etc/rc.d/rc.chrony status
  chronyc tracking                  how far off the clock is, and how it is being corrected
  chronyc sources -v                the servers it uses
  date ; sudo hwclock --show
Other servers: server or pool lines in /etc/chrony.conf, then sudo /etc/rc.d/rc.chrony restart.
At shutdown rc.6 copies the system clock to the hardware clock, which keeps UTC
(/etc/hardwareclock). Time zone: see locale.

## Scheduled jobs: crond
crond (Slackware's dcron, /etc/rc.d/rc.crond) runs crontab jobs. root's crontab runs the scripts
in /etc/cron.hourly, cron.daily, cron.weekly and cron.monthly (logrotate among the daily ones),
the daily ones at 04:40.
  sudo crontab -l                   root's jobs
  crontab -e                        your own (also: sudo crontab -e for root's)
A line is minute, hour, day of month, month, day of week, then the command:
  30 3 * * *  rsync -a /home/you/ /media/backup/       every day at 03:30
  30 12 * * 0 /sbin/fstrim -a                          Sundays at 12:30 (root's crontab)
A job missed while the laptop was asleep or off is not run later. A script of your own in
/etc/cron.daily (executable) runs with the others.

## Once, later
  sleep 600 && notify-send 'Tea'     in a terminal

See also: rc, locale (time zone), filesystems (TRIM) ; man chronyc ; man chrony.conf ;
man crontab ; man crond
