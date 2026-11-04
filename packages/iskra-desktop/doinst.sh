config() {
  NEW="$1"; OLD="$(dirname "$NEW")/$(basename "$NEW" .new)"
  if [ ! -r "$OLD" ]; then mv "$NEW" "$OLD"
  elif [ "$(md5sum < "$OLD")" = "$(md5sum < "$NEW")" ]; then rm "$NEW"; fi
}
if [ -x usr/bin/update-desktop-database ]; then
  chroot . /usr/bin/update-desktop-database -q usr/share/applications >/dev/null 2>&1
fi
# Iskra's services: rc.local starts them at boot, rc.local_shutdown stops them
if ! grep -q rc.iskra etc/rc.d/rc.local 2>/dev/null; then
  printf '\n# Iskra: its services (battery, temperature, clock, firewall, the tutor)\n[ -x /etc/rc.d/rc.iskra ] && /etc/rc.d/rc.iskra start\n' >> etc/rc.d/rc.local
fi
if [ ! -f etc/rc.d/rc.local_shutdown ]; then
  printf '#!/bin/sh\n# run by rc.0 and rc.6 at shutdown and restart\n' > etc/rc.d/rc.local_shutdown
fi
chmod 755 etc/rc.d/rc.local etc/rc.d/rc.local_shutdown
if ! grep -q rc.iskra etc/rc.d/rc.local_shutdown; then
  printf '[ -x /etc/rc.d/rc.iskra ] && /etc/rc.d/rc.iskra stop\n' >> etc/rc.d/rc.local_shutdown
fi
# Slackware's own services Iskra uses: NetworkManager (nmtui) and Bluetooth
for s in rc.networkmanager rc.bluetooth; do [ -f etc/rc.d/$s ] && chmod 755 etc/rc.d/$s; done
# The first console: ly, Iskra's login screen (usr/lib/iskra/login falls back to a text login)
if [ -f etc/inittab ] && ! grep -q 'usr/lib/iskra/login' etc/inittab; then
  sed -i 's|^c1:12345:respawn:.*|c1:12345:respawn:/sbin/agetty --noclear -n -l /usr/lib/iskra/login 38400 tty1 linux|' etc/inittab
fi
# ly's settings, if ly is installed already (iskra-install sets them too): on the first console,
# Iskra's look, the Iskra session
if [ -f etc/ly/config.ini ]; then
  set_ly() { if grep -q "^$1 *=" etc/ly/config.ini; then sed -i "s|^$1 *=.*|$1 = $2|" etc/ly/config.ini; else echo "$1 = $2" >> etc/ly/config.ini; fi; }
  set_ly tty 1; set_ly animation none; set_ly bg 0x00000000; set_ly fg 0x00FFFFFF
  set_ly border_fg 0x00D52B1E; set_ly box_title ИСКРА; set_ly hide_version_string true
  set_ly default_input password; set_ly xsessions /usr/share/xsessions; set_ly waylandsessions null
  set_ly brightness_down_cmd "/usr/bin/brightnessctl -q -n s 10%-"
  set_ly brightness_up_cmd "/usr/bin/brightnessctl -q -n s +10%"
fi
