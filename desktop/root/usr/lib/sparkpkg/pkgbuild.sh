# pkgbuild.sh: runs an Arch PKGBUILD the way Arch's makepkg does, and makes Slackware packages
# of what it builds. Read by the SlackBuilds sparkpkg writes; they set PKGBASE, PACKAGES (the
# split packages wanted), TAG (_aur or _arch) and OUTPUT, then call sparkpkg_build, as root.
#
# The recipe never runs as root: downloading, building and packaging happen as the user
# "sparkpkg" (or SPARKPKG_USER), under fakeroot, so files inside the package get root's
# ownership without the recipe having it. Only Slackware's installpkg, later, runs as root.
#
# Like makepkg, with makepkg.conf's usual settings: x86_64, -O2 -march=x86-64 -mtune=generic,
# options strip !libtool !staticlibs emptydirs zipman purge (a recipe's options=() overrides them),
# check() skipped unless SPARKPKG_CHECK=1. Then, for Slackware: systemd units are left out (Iskra
# starts services with rc.d scripts) after turning sysusers.d and tmpfiles.d entries into the
# install script; backup=() files are installed as .new, so your edited copies stay; the recipe's
# .install hooks run from doinst.sh; and pkgdesc and url become the slack-desc.

sparkpkg_build() {
  [[ $EUID -eq 0 ]] || { echo "sparkpkg: run the SlackBuild as root (it drops to an ordinary user to build)" >&2; return 1; }
  command -v fakeroot >/dev/null || { echo "sparkpkg: fakeroot is needed: sparkpkg install fakeroot" >&2; return 1; }
  local user=${SPARKPKG_USER:-sparkpkg}
  id -u "$user" >/dev/null 2>&1 || user=nobody
  local recipe; recipe=$(pwd)
  local work=${SPARKPKG_WORK:-/tmp/sparkpkg}/$PKGBASE
  rm -rf "$work"; mkdir -p "$work"/{src,pkg,home} "${SRCDEST:=/var/cache/sparkpkg/sources}" "$OUTPUT"
  mkdir -p "$work/recipe"; cp -a "$recipe/." "$work/recipe/"
  chown -R "$user:" "$work" "$SRCDEST"
  chmod 0755 "$work"
  local out; out=$(mktemp -d "$work/out.XXXX"); chown "$user:" "$out"
  setpriv --reuid="$user" --regid="$(id -g "$user")" --init-groups --reset-env --inh-caps=-all \
    env -i PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin HOME="$work/home" LANG=C.UTF-8 \
        TERM="${TERM:-dumb}" MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}" SPARKPKG_CHECK="${SPARKPKG_CHECK:-0}" \
        _SPK_PACKAGES="$PACKAGES" _SPK_TAG="$TAG" SRCDEST="$SRCDEST" _SPK_OUT="$out" _SPK_WORK="$work" \
        http_proxy="${http_proxy:-}" https_proxy="${https_proxy:-}" no_proxy="${no_proxy:-}" \
        ${SSL_CERT_FILE:+SSL_CERT_FILE="$SSL_CERT_FILE"} ${CURL_CA_BUNDLE:+CURL_CA_BUNDLE="$CURL_CA_BUNDLE"} \
        ${GIT_SSL_CAINFO:+GIT_SSL_CAINFO="$GIT_SSL_CAINFO"} \
    fakeroot -- bash -c '. /usr/lib/sparkpkg/pkgbuild.sh && _spk_run' || return 1
  local f n=0
  for f in "$out"/*.t?z; do
    [[ -e $f ]] || continue
    mv "$f" "$OUTPUT/"; chown root:root "$OUTPUT/${f##*/}"; echo "$OUTPUT/${f##*/}"; n=$((n + 1))
  done
  rm -rf "$work"
  (( n > 0 ))
}

# ---------------------------------------------------------------- below here: the ordinary user

msg()     { printf '==> %s\n' "$*"; }
msg2()    { printf '  -> %s\n' "$*"; }
plain()   { printf '    %s\n' "$*"; }
warning() { printf '==> WARNING: %s\n' "$*" >&2; }
error()   { printf '==> ERROR: %s\n' "$*" >&2; }
_die()    { error "$*"; exit 1; }

_spk_env() {
  export CARCH=x86_64 CHOST=x86_64-pc-linux-gnu
  export CPPFLAGS=""
  export CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection"
  export CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
  export LDFLAGS="-Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs"
  export LTOFLAGS="-flto=auto" RUSTFLAGS="-Cforce-frame-pointers=yes"
  export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig
  export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(date +%s)}
  export startdir="$_SPK_WORK/recipe" srcdir="$_SPK_WORK/src" BUILDDIR="$_SPK_WORK"
}

# the checksum arrays makepkg knows, strongest first
_SPK_SUMS=(b2 sha512 sha384 sha256 sha224 sha1 md5)

_spk_name() {   # a source entry's file name in srcdir
  local s=$1
  if [[ $s == *::* ]]; then echo "${s%%::*}"; return; fi
  s=${s%%#*}; s=${s%%\?*}; s=${s%/}
  case $s in *.git) s=${s%.git} ;; esac
  echo "${s##*/}"
}

_spk_fetch() {  # one source entry -> $SRCDEST, linked into srcdir
  local entry=$1 name url
  name=$(_spk_name "$entry"); url=${entry#*::}
  [[ $entry == *::* ]] || url=$entry
  case $url in
    git+*|*.git|*.git#*)
      # Arch's form: git+URL#fragment?query, as in  git+https://host/x.git#commit=abc123?signed
      local u=${url#git+} frag= query=
      [[ $u == *\?* ]] && { query=${u##*\?}; u=${u%\?*}; }
      [[ $u == *#* ]] && { frag=${u#*#}; u=${u%%#*}; }
      if [[ -d $SRCDEST/$name.git ]]; then
        msg2 "updating $name (git)"; git -C "$SRCDEST/$name.git" fetch --all --prune --tags -q
      else
        msg2 "cloning $name (git)"; git clone --mirror -q "$u" "$SRCDEST/$name.git"
      fi
      rm -rf "$srcdir/$name"; git clone -q "$SRCDEST/$name.git" "$srcdir/$name"
      local ref=
      case $frag in
        tag=*)    ref="tags/${frag#tag=}" ;;
        commit=*) ref=${frag#commit=} ;;
        branch=*) ref="origin/${frag#branch=}" ;;
        "")       ;;
        *)        _die "$name: unknown git source fragment #$frag" ;;
      esac
      if [[ -n $ref ]]; then    # exactly what the recipe pins, or nothing
        git -C "$srcdir/$name" checkout -q --detach "$ref" || _die "$name: the recipe's ${frag%%=*} ${frag#*=} isn't in the repository"
      fi
      git -C "$srcdir/$name" submodule -q init 2>/dev/null || true
      [[ $query == signed ]] && _spk_gitsig "$name" "${ref:-HEAD}"
      ;;
    http://*|https://*|ftp://*|file://*)
      if [[ ! -s $SRCDEST/$name ]]; then
        msg2 "downloading $name"
        curl -fL --retry 3 --connect-timeout 30 -o "$SRCDEST/$name.part" "$url" && mv "$SRCDEST/$name.part" "$SRCDEST/$name" ||
          _die "could not download $url"
      fi
      ln -sf "$SRCDEST/$name" "$srcdir/$name" ;;
    *)
      [[ -e $startdir/$url ]] || _die "the recipe's file $url is missing"
      ln -sf "$startdir/$url" "$srcdir/$name" ;;
  esac
}

_spk_verify() {  # array-of-sources name, suffix ("" or _x86_64)
  local -n src=$1; local sfx=$2 kind i checked=0
  for kind in "${_SPK_SUMS[@]}"; do
    local -n sums="${kind}sums${sfx}" 2>/dev/null || continue
    [[ ${#sums[@]} -gt 0 ]] || { unset -n sums; continue; }
    [[ ${#sums[@]} -eq ${#src[@]} ]] || _die "${kind}sums$sfx has ${#sums[@]} entries for ${#src[@]} sources"
    for i in "${!src[@]}"; do
      local f; f=$(_spk_name "${src[i]}")
      [[ ${sums[i]} == SKIP ]] && continue
      [[ -d $srcdir/$f ]] && continue
      local got; got=$("${kind}sum" "$srcdir/$f" | cut -d' ' -f1)
      [[ $got == "${sums[i]}" ]] || _die "$f does not match the recipe's ${kind} checksum"
    done
    checked=1; unset -n sums
  done
  (( checked || ${#src[@]} == 0 )) || warning "the recipe gives no checksums for source$sfx"
}

_spk_gitsig() {   # ?signed: the pinned commit or tag must carry a signature from validpgpkeys
  local name=$1 ref=$2 keys=("$startdir"/keys/pgp/*.asc) g fpr
  if [[ ${#validpgpkeys[@]} -eq 0 || ! -e ${keys[0]} ]]; then
    warning "$name: the recipe asks for a signed ${ref#tags/}, but doesn't include its keys; relying on the pinned commit"
    return 0
  fi
  g=$(mktemp -d); chmod 700 "$g"
  gpg --homedir "$g" --batch --quiet --import "${keys[@]}" 2>/dev/null
  if [[ $ref == tags/* ]]; then
    fpr=$(GNUPGHOME=$g git -C "$srcdir/$name" verify-tag --raw "${ref#tags/}" 2>&1 | awk '$2 == "VALIDSIG" { print $NF }')
  else
    fpr=$(GNUPGHOME=$g git -C "$srcdir/$name" verify-commit --raw "$ref" 2>&1 | awk '$2 == "VALIDSIG" { print $NF }')
  fi
  rm -rf "$g"
  [[ -n $fpr && " ${validpgpkeys[*]^^} " == *" ${fpr^^} "* ]] || _die "$name: ${ref#tags/} is not signed by one of the recipe's keys"
  msg2 "$name: ${ref#tags/} signature good ($fpr)"
}

_spk_pgp() {    # makepkg's signature check: each .sig/.asc source against the recipe's validpgpkeys
  [[ ${#validpgpkeys[@]} -gt 0 ]] || return 0
  local keys=("$startdir"/keys/pgp/*.asc) entry f data g
  if [[ ! -e ${keys[0]} ]]; then
    warning "the recipe names signing keys but doesn't include them; relying on its checksums"
    return 0
  fi
  g=$(mktemp -d); chmod 700 "$g"
  gpg --homedir "$g" --batch --quiet --import "${keys[@]}" 2>/dev/null
  for entry in "$@"; do
    f=$(_spk_name "$entry")
    case $f in *.sig|*.asc|*.sign) ;; *) continue ;; esac
    data=${f%.*}
    [[ -e $srcdir/$data ]] || continue
    local fpr; fpr=$(gpg --homedir "$g" --batch --status-fd 1 --verify "$srcdir/$f" "$srcdir/$data" 2>/dev/null |
                     awk '$2 == "VALIDSIG" { print $NF }')
    [[ -n $fpr && " ${validpgpkeys[*]^^} " == *" ${fpr^^} "* ]] ||
      { rm -rf "$g"; _die "$data is not signed by one of the recipe's keys"; }
    msg2 "$data: signature good ($fpr)"
  done
  rm -rf "$g"
}

_spk_extract() {
  local entry f
  for entry in "$@"; do
    f=$(_spk_name "$entry")
    [[ " ${noextract[*]} " == *" $f "* || -d $srcdir/$f ]] && continue
    case ${f,,} in
      *.sig|*.asc|*.sign|*.pgp|*.minisig) continue ;;     # signatures: checked, never unpacked
      *.tar|*.tar.gz|*.tar.bz2|*.tar.xz|*.tar.zst|*.tar.lz|*.tar.lzma|*.tar.lz4|*.tar.z|*.tgz|*.tbz|*.tbz2|*.txz|*.tzst|*.zip|*.7z|*.deb|*.rpm|*.cpio|*.xpi|*.crx|*.whl|*.jar)
        msg2 "extracting $f"; bsdtar -xf "$srcdir/$f" -C "$srcdir" || _die "could not extract $f" ;;
      *.gz)  gzip -dc  "$srcdir/$f" > "$srcdir/${f%.*}" ;;
      *.bz2) bzip2 -dc "$srcdir/$f" > "$srcdir/${f%.*}" ;;
      *.xz)  xz -dc    "$srcdir/$f" > "$srcdir/${f%.*}" ;;
      *.zst) zstd -dcq "$srcdir/$f" > "$srcdir/${f%.*}" ;;
    esac
  done
}

_spk_has() { declare -F "$1" >/dev/null; }

_spk_step() {   # run one PKGBUILD function in srcdir, stopping at its first failing command, like
  # makepkg. (Not inside "&&" or "||": bash switches off stop-on-error for everything run there.)
  local _spk_fn=$1
  msg "$_spk_fn()"
  ( cd "$srcdir" || exit 1
    set -eE
    trap 'error "$_spk_fn() stopped: line $LINENO of the recipe failed"' ERR
    "$_spk_fn" )
  local rc=$?
  [[ $rc -eq 0 ]] || _die "$_spk_fn() failed (exit $rc)"
}

_spk_opt() {    # is option $1 on? recipe's options=() first, then makepkg.conf's defaults
  local o
  for o in "${options[@]}"; do
    [[ $o == "$1" ]] && return 0
    [[ $o == "!$1" ]] && return 1
  done
  [[ " strip docs emptydirs zipman purge " == *" $1 "* ]]
}

_spk_tidy() {   # makepkg's tidying, then Slackware's needs, in $pkgdir
  local name=$1
  cd "$pkgdir"
  _spk_opt docs || rm -rf usr/share/doc usr/share/gtk-doc
  _spk_opt libtool || find . -name '*.la' -type f -delete
  _spk_opt staticlibs || find . -name '*.a' -type f \( -path '*/lib/*' -o -path '*/lib64/*' \) -delete
  if _spk_opt purge; then
    rm -f usr/share/info/dir usr/lib/perl5/*/perllocal.pod
    find . -name .packlist -delete
  fi
  if _spk_opt zipman; then
    find usr/share/man usr/share/info -type f ! -name '*.gz' ! -name '*.bz2' ! -name '*.xz' -exec gzip -9nf {} + 2>/dev/null || true
    find usr/share/man -type l ! -name '*.gz' 2>/dev/null </dev/null | while read -r l; do
      t=$(readlink "$l"); ln -sf "$t.gz" "$l.gz"; rm -f "$l"; done
  fi
  if _spk_opt strip; then
    find . -type f -perm -u+w 2>/dev/null | while read -r f; do
      case $(file -bi "$f") in
        *application/x-sharedlib*)  strip --strip-unneeded "$f" 2>/dev/null || true ;;
        *application/x-executable*|*application/x-pie-executable*) strip --strip-all "$f" 2>/dev/null || true ;;
        *application/x-object*)     [[ $f == *.ko ]] || strip --strip-debug "$f" 2>/dev/null || true ;;
      esac
    done
  fi
  mkdir -p install
  : > install/doinst.sh
  # sysusers.d and tmpfiles.d: what systemd would do at boot, done once at install instead
  local f line
  for f in usr/lib/sysusers.d/*.conf; do
    [[ -e $f ]] || continue
    while read -r t n id gecos home shell; do
      case $t in
        g) echo "chroot . groupadd -r ${id:+-g $id} $n 2>/dev/null || true" ;;
        u) echo "chroot . groupadd -r $n 2>/dev/null || true"
           echo "chroot . useradd -r -g $n ${id:+$( [[ $id == [0-9]* ]] && echo -u "$id" )} -d ${home:-/} -s ${shell:-/bin/false} $n 2>/dev/null || true" ;;
        m) echo "chroot . usermod -a -G $id $n 2>/dev/null || true" ;;
      esac
    done < <(grep -v '^\s*\(#\|$\)' "$f" | sed 's/"[^"]*"/-/') >> install/doinst.sh
  done
  for f in usr/lib/tmpfiles.d/*.conf; do
    [[ -e $f ]] || continue
    while read -r t p m u g rest; do
      [[ $t == d* || $t == D* ]] || continue
      [[ $p == /run/* || $p == /tmp/* ]] && continue
      echo "mkdir -p .${p}; chmod ${m//-/0755} .${p}; chown ${u//-/root}:${g//-/root} .${p} 2>/dev/null || true"
    done < <(grep -v '^\s*\(#\|$\)' "$f") >> install/doinst.sh
  done
  if [[ -d usr/lib/systemd ]]; then
    local units; units=$(find usr/lib/systemd -name '*.service' -printf '%f ' 2>/dev/null)
    [[ -n $units ]] && warning "$name comes with systemd services ($units); Iskra starts services from /etc/rc.d"
    rm -rf usr/lib/systemd
  fi
  rm -rf usr/lib/sysusers.d usr/lib/tmpfiles.d
  # backup=(): config files, installed as .new so an edited copy is kept
  local b
  if [[ ${#backup[@]} -gt 0 ]]; then
    cat >> install/doinst.sh <<'DOINST'
config() {
  NEW="$1"; OLD="$(dirname "$NEW")/$(basename "$NEW" .new)"
  if [ ! -r "$OLD" ]; then mv "$NEW" "$OLD"
  elif [ "$(cat "$OLD" | md5sum)" = "$(cat "$NEW" | md5sum)" ]; then rm "$NEW"; fi
}
DOINST
    for b in "${backup[@]}"; do
      [[ -f $b ]] || continue
      mv "$b" "$b.new"; echo "config $b.new" >> install/doinst.sh
    done
  fi
  # the recipe's install hooks
  if [[ -n ${install:-} && -f $startdir/$install ]]; then
    { echo "# hooks from the recipe's $install"; cat "$startdir/$install"; echo
      echo "if [ \"\$(ls var/lib/pkgtools/packages | grep -c '^$name-[^-]*-[^-]*-[^-]*\$')\" -gt 1 ]"
      echo "then type post_upgrade >/dev/null 2>&1 && post_upgrade '$_spk_ver' || true"
      echo "else type post_install >/dev/null 2>&1 && post_install '$_spk_ver' || true; fi"; } >> install/doinst.sh
  fi
  [[ -s install/doinst.sh ]] || rm -f install/doinst.sh
  # the description Slackware shows
  local desc short; desc=${pkgdesc:-$name}
  short=$desc                                   # the first line's summary: whole words, 70 wide
  while (( ${#name} * 2 + ${#short} + 5 > 72 )) && [[ $short == *" "* ]]; do short=${short% *}; done
  [[ $short == "$desc" ]] || short="$short..."
  { printf '%s: %s (%s)\n%s:\n' "$name" "$name" "$short" "$name"
    fold -s -w 70 <<<"$desc" | sed "s/^/$name: /" | head -n 5
    printf '%s:\n' "$name"
    printf '%s: Made by sparkpkg from %s.\n' "$name" "$([[ $_SPK_TAG == _aur ]] && echo "an AUR recipe" || echo "Arch Linux's recipe")"
    printf '%s: %s\n' "$name" "${url:-}"; } > install/slack-desc
  while [[ $(wc -l < install/slack-desc) -lt 11 ]]; do echo "$name:" >> install/slack-desc; done
  _spk_opt emptydirs || find . -mindepth 1 -type d -empty -delete
  return 0
}

_spk_run() {
  set -o pipefail
  _spk_env
  cd "$startdir" || exit 1
  source ./PKGBUILD || _die "the PKGBUILD has errors"
  [[ -n ${pkgbase:-} ]] || pkgbase=${pkgname[0]}

  msg "Getting the sources for $pkgbase"
  local all=("${source[@]}" "${source_x86_64[@]}")
  for s in "${all[@]}"; do _spk_fetch "$s"; done
  _spk_verify source ""; _spk_verify source_x86_64 _x86_64
  _spk_pgp "${all[@]}"
  _spk_extract "${all[@]}"

  if _spk_has pkgver; then
    pkgver=$(cd "$srcdir" || exit 1; set -e; pkgver) || _die "pkgver() failed"
    msg2 "version from the source: $pkgver"
  fi
  if _spk_has prepare; then _spk_step prepare; fi
  if _spk_has build; then _spk_step build; fi
  if [[ $SPARKPKG_CHECK == 1 ]] && _spk_has check; then _spk_step check; fi

  local parch=x86_64; [[ " ${arch[*]} " == *" any "* ]] && parch=noarch
  local ver=${pkgver//[:-]/_} rel=${pkgrel}
  _spk_ver="${epoch:+$epoch:}$pkgver-$pkgrel"
  local name
  for name in $_SPK_PACKAGES; do
    export pkgdir="$_SPK_WORK/pkg/$name"; rm -rf "$pkgdir"; mkdir -p "$pkgdir"
    # a split package's own settings replace the base's while it is packaged
    local fn=package; _spk_has "package_$name" && fn="package_$name"
    _spk_has $fn || _die "the recipe has no $fn()"
    msg "$fn()"
    ( pkgname=$name
      cd "$srcdir" || exit 1
      set -eE
      trap 'error "$fn() stopped: line $LINENO of the recipe failed"' ERR
      $fn
      set +eE; trap - ERR
      declare -p pkgdesc url backup options install 2>/dev/null > "$_SPK_WORK/pkg/$name.vars"
      exit 0 )
    local rc=$?
    [[ $rc -eq 0 ]] || _die "$fn() failed (exit $rc)"
    ( source "$_SPK_WORK/pkg/$name.vars" 2>/dev/null; _spk_tidy "$name" ) || exit 1
    local file="$_SPK_OUT/$name-$ver-$parch-$rel$_SPK_TAG.txz"
    msg "Making $(basename "$file")"
    ( cd "$pkgdir" && /sbin/makepkg -l y -c n "$file" > "$_SPK_WORK/makepkg.log" 2>&1 ) ||
      { cat "$_SPK_WORK/makepkg.log"; _die "makepkg failed"; }
  done
}
