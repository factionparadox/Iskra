config() {
  NEW="$1"; OLD="$(dirname "$NEW")/$(basename "$NEW" .new)"
  if [ ! -r "$OLD" ]; then mv "$NEW" "$OLD"
  elif [ "$(md5sum < "$OLD")" = "$(md5sum < "$NEW")" ]; then rm "$NEW"; fi
}
if [ -x usr/bin/update-desktop-database ]; then
  chroot . /usr/bin/update-desktop-database -q usr/share/applications >/dev/null 2>&1
fi
