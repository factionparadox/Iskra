config() {
  NEW="$1"; OLD="$(dirname "$NEW")/$(basename "$NEW" .new)"
  if [ ! -r "$OLD" ]; then mv "$NEW" "$OLD"
  elif [ "$(md5sum < "$OLD")" = "$(md5sum < "$NEW")" ]; then rm "$NEW"; fi
}
takeover() {
  # slpkg's package installs its stock settings first; a file that is still stock (no mention of
  # Iskra) is replaced by Iskra's, with slpkg's kept beside it. A file you edited is left alone.
  NEW="$1"; OLD="$(dirname "$NEW")/$(basename "$NEW" .new)"
  if [ -r "$OLD" ] && ! grep -q Iskra "$OLD"; then mv "$OLD" "$OLD.slpkg-stock"; fi
  config "$NEW"
}
# the ordinary user that builds Arch and AUR recipes, so they never run as root
if ! grep -q '^sparkpkg:' etc/group; then chroot . /usr/sbin/groupadd -r sparkpkg; fi
if ! grep -q '^sparkpkg:' etc/passwd; then
  chroot . /usr/sbin/useradd -r -g sparkpkg -d /var/lib/sparkpkg -s /bin/false -c "sparkpkg builds" sparkpkg
fi
chroot . /bin/chown sparkpkg:sparkpkg /var/cache/sparkpkg 2>/dev/null
if [ -x sbin/ldconfig ]; then chroot . /sbin/ldconfig 2>/dev/null; fi
