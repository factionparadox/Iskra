config() {
  NEW="$1"; OLD="$(dirname "$NEW")/$(basename "$NEW" .new)"
  if [ ! -r "$OLD" ]; then mv "$NEW" "$OLD"
  elif [ "$(md5sum < "$OLD")" = "$(md5sum < "$NEW")" ]; then rm "$NEW"; fi
}
[ -e etc/mango/config.conf.new ] && config etc/mango/config.conf.new
