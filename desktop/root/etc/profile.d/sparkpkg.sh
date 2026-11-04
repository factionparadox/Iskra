# Programs sparkpkg builds from Arch and AUR recipes keep Arch's layout (/usr/lib, not /usr/lib64);
# /etc/ld.so.conf.d/sparkpkg.conf finds their libraries, this finds their pkg-config files.
case ":${PKG_CONFIG_PATH}:" in *:/usr/lib/pkgconfig:*) ;; *)
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+$PKG_CONFIG_PATH:}/usr/lib64/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig" ;; esac
