if [ -x usr/bin/fc-cache ]; then
  chroot . /usr/bin/fc-cache -f usr/share/fonts/TTF >/dev/null 2>&1
fi
