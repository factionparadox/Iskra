# lib.sh: the start every Avalon SlackBuild shares (read with  . ../lib.sh).
# Sets PRGNAM VERSION BUILD TAG ARCH TMP PKG OUTPUT CWD, the usual SLKCFLAGS, a clean $PKG,
# and slackdesc(), which installs the slack-desc beside the SlackBuild. Packages end up in $OUTPUT.
set -e
CWD=$(pwd)
. "$CWD/$PRGNAM.info"
BUILD=${BUILD:-1}
TAG=${TAG:-_avalon}
PKGTYPE=${PKGTYPE:-txz}
ARCH=${ARCH:-x86_64}
TMP=${TMP:-/tmp/avalon-sb}
PKG=$TMP/package-$PRGNAM
OUTPUT=${OUTPUT:-/tmp}
SLKCFLAGS="-O2 -march=x86-64 -mtune=generic -fPIC"
LIBDIRSUFFIX=64
rm -rf "$PKG"; mkdir -p "$TMP" "$PKG" "$OUTPUT"
slackdesc() { install -Dm644 "$CWD/slack-desc" "$PKG/install/slack-desc"; }
finish() {   # the usual tidying, then the package
  cd "$PKG"
  find . -type f -print0 | xargs -0 file 2>/dev/null | grep -e "executable" -e "shared object" |
    grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2>/dev/null || true
  [ -d usr/man ] && find usr/man -type f ! -name '*.gz' -exec gzip -9 {} +
  [ -d usr/share/man ] && find usr/share/man -type f ! -name '*.gz' -exec gzip -9 {} +
  slackdesc
  [ -f "$CWD/doinst.sh" ] && install -m644 "$CWD/doinst.sh" "$PKG/install/doinst.sh"
  /sbin/makepkg -l y -c n "$OUTPUT/$PRGNAM-$VERSION-$ARCH-$BUILD$TAG.$PKGTYPE"
}
