# SlackBuilds: how a Slackware package is made

A SlackBuild is a shell script that builds one program into a Slackware package: it unpacks the
source, compiles it, installs it into a folder of its own instead of into /, and ends with
makepkg (see: pkgtools), which packs that folder into a .txz. Slackware builds its own packages
this way, and so does everyone who builds for it: slackbuilds.org, Ponce, AlienBOB, conraid and
Iskra. You never have to: sparkpkg installs ready-made packages, and builds from a SlackBuild
only when no one has one (the ponce repository; see: repositories). But they are short, and
worth reading.

## The files of a SlackBuild
A folder named after the program, with:
  foo.SlackBuild     the script
  foo.info           where the source comes from, and what it needs (below)
  slack-desc         the description installpkg shows: eleven lines, each starting "foo:"
  README             what it is, and any options
  doinst.sh          (if needed) run after installing: settings files as .new, links, icons
The .info file is plain shell variables:
  PRGNAM="foo"
  VERSION="1.2"
  HOMEPAGE="https://example.org/foo"
  DOWNLOAD="https://example.org/foo-1.2.tar.gz"
  MD5SUM="5d41402abc4b2a76b9719d911017c592"
  DOWNLOAD_x86_64=""            (a different download for 64-bit, if there is one)
  MD5SUM_x86_64=""
  REQUIRES="bar baz"            what must be installed first; Slackware's own packages are
                                never listed, since a full Slackware is assumed
  MAINTAINER="..."
REQUIRES is the only dependency information there is: slpkg reads it for the ponce repository,
and sparkpkg's recipes (see: sparkpkg) turn each Arch dependency into a REQUIRES of the same kind.

## A SlackBuild, shortened
  CWD=$(pwd)
  PRGNAM=foo
  VERSION=${VERSION:-1.2}
  BUILD=${BUILD:-1}
  TAG=${TAG:-_SBo}
  TMP=${TMP:-/tmp/SBo} ; PKG=$TMP/package-$PRGNAM ; OUTPUT=${OUTPUT:-/tmp}
  SLKCFLAGS="-O2 -fPIC" ; LIBDIRSUFFIX="64"

  rm -rf $PKG ; mkdir -p $TMP $PKG $OUTPUT
  cd $TMP ; rm -rf $PRGNAM-$VERSION ; tar xvf $CWD/$PRGNAM-$VERSION.tar.gz
  cd $PRGNAM-$VERSION
  CFLAGS="$SLKCFLAGS" ./configure --prefix=/usr --libdir=/usr/lib${LIBDIRSUFFIX} \
    --sysconfdir=/etc --mandir=/usr/man --docdir=/usr/doc/$PRGNAM-$VERSION
  make
  make install DESTDIR=$PKG
  mkdir -p $PKG/install ; cat $CWD/slack-desc > $PKG/install/slack-desc
  cd $PKG ; /sbin/makepkg -l y -c n $OUTPUT/$PRGNAM-$VERSION-x86_64-$BUILD$TAG.txz
Things that make it Slackware's: libraries go in /usr/lib64 on 64-bit (LIBDIRSUFFIX),
manual pages in /usr/man, documentation in /usr/doc/NAME-VERSION, and the build number and tag
end the package's name.

## Building one by hand
Put the source named in DOWNLOAD beside the SlackBuild (check it: md5sum FILE against
MD5SUM), install what REQUIRES lists, then, as root:
  cd foo
  sudo sh foo.SlackBuild                      the package lands in /tmp (OUTPUT)
  sudo installpkg /tmp/foo-1.2-x86_64-1_SBo.txz
Compilers and headers are installed (Slackware's d series), so this works on Iskra as it is.
Variables in front change the defaults:  sudo BUILD=2 OUTPUT=~/pkgs sh foo.SlackBuild

## Ponce's SlackBuilds
slackbuilds.org writes SlackBuilds for Slackware's releases; Ponce keeps a copy of them that
builds on -current, which is what Iskra runs. That is the ponce repository: slpkg downloads
Ponce's SlackBuilds, and when you install something only Ponce has, it fetches the source,
checks its MD5, builds and installs it, and its REQUIRES first (see: slpkg).
  https://github.com/Ponce/slackbuilds (branch current)     the SlackBuilds themselves
  https://slackbuilds.org/                                    their pages, READMEs and search

## Iskra's own SlackBuilds
Iskra's repository (https://github.com/factionparadox/Iskra) builds its packages the same way,
in a clean Slackware -current system on GitHub's CI (build/build-packages), and publishes them,
signed, as the iskra repository. packages/LIST says what is built and from where: Iskra's own
SlackBuilds in packages/NAME/, Ponce's (ponce:PATH), or Arch and AUR recipes through sparkpkg
(arch:NAME, aur:NAME). Iskra's .info files give a SHA256SUM rather than an MD5SUM, and may name
a git commit as the download (git+URL#commit=HASH). They share packages/lib.sh, which sets the
tag _iskra and the usual folders.

## Changing X-терминал
Like every suckless program, X-терминал's settings are compiled in: config.h (the look and the
keys) and patches.h (1 switches a patch on), in packages/x-terminal. To build your own:
  git clone https://github.com/factionparadox/Iskra ~/iskra
  cd ~/iskra/packages/x-terminal
  mcedit config.h                              (and patches.h)
  c=$(sed -n 's/.*commit=\([0-9a-f]*\).*/\1/p' x-terminal.info)
  git clone -q https://github.com/bakkeby/st-flexipatch.git /tmp/stf
  git -C /tmp/stf archive --format=tar.gz --prefix=st-flexipatch-$c/ -o $PWD/st-flexipatch-$c.tar.gz $c
  sudo BUILD=2 TAG=_local sh x-terminal.SlackBuild
  sudo upgradepkg /tmp/x-terminal-*-x86_64-2_local.txz
So that sparkpkg upgrade doesn't put Iskra's back over yours, pin it:  sudo slpkg pin x-terminal
(see: slpkg). To go back to Iskra's:
  sudo slpkg pin -u x-terminal ; sudo removepkg x-terminal ; sudo sparkpkg install x-terminal

See also: pkgtools, slpkg, sparkpkg, repositories ; man makepkg ;
https://slackbuilds.org/howto/ ; https://slackbuilds.org/guidelines/
