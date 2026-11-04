# slpkg: underneath sparkpkg

slpkg is the Slackware package manager sparkpkg is built on. Slackware's own tools (installpkg,
upgradepkg, removepkg: see pkgtools) handle one package file at a time and know nothing of
dependencies; slpkg reads whole repositories, works out what a package needs from their lists,
downloads, checks and installs it all through those same tools. Iskra uses slpkg 6.1.7 with a
few changes of its own (below). Day to day you use sparkpkg (see: sparkpkg), which runs slpkg
for you; this page is for when you want to know what it is doing, or to use slpkg yourself:

  sparkpkg slpkg ...              slpkg itself, with any of its options
  slpkg ...                       the same, directly (with sudo for anything that changes things)

## The commands sparkpkg uses
  slpkg update                    fetch every repository's latest lists (sparkpkg sync)
  slpkg upgrade -o all            upgrade from every repository, in priority order
                                  (sparkpkg upgrade; with --dry-run, only show what would change)
  slpkg install foo -o all        install foo and what it needs (sparkpkg install)
  slpkg remove foo                remove it (sparkpkg remove)
  slpkg search word               look in the repositories (sparkpkg search adds Arch and the AUR)
  slpkg info foo                  what foo is
  slpkg history                   what was installed, upgraded and removed, and when
  slpkg rollback                  slpkg's own undo: packages that were installed OR UPGRADED are
                                  removed, packages that were removed are installed again. After
                                  an upgrade that removes what was upgraded, so on Iskra use
                                  sparkpkg undo instead, which puts the old versions back
  slpkg why foo                   what needs foo
  slpkg orphans                   packages slpkg installed as dependencies that nothing needs
                                  any more

## A few more worth knowing
  slpkg file-search NAME          which package, in any repository, has a file called NAME
  slpkg list-files foo            the files an installed package put on the disk
  slpkg verify                    check that every installed package's files are still there
  sudo slpkg pin foo              keep foo as it is: slpkg upgrade leaves it alone
  sudo slpkg pin -u foo           let it be upgraded again ; slpkg pin lists what is pinned
  sudo slpkg blacklist foo        never install or upgrade foo at all (-r takes it off again)
All of them work through sparkpkg too (sparkpkg slpkg pin foo). slpkg help, and man slpkg, list
the rest.

## Its settings
  /etc/slpkg/slpkg.toml           how it behaves: it asks before changing anything, checks every
                                  GPG signature and MD5 checksum, installs with
                                  upgradepkg --install-new, uses mcedit and less, and remakes
                                  GRUB's menu (grub-mkconfig) when the kernel changes
  /etc/slpkg/repositories.toml    which repositories, their mirrors, and PRIORITY under
                                  [ALL_REPOS]: the order sparkpkg looks in (see: repositories)
  /etc/slpkg/blacklist.toml       packages slpkg should never touch (empty)
All three are settings files of the sparkpkg package: if you edit one, an update leaves yours in
place and puts the new one beside it as .new (see: pkgtools).
What slpkg records is in /var/log/slpkg: history.log (every change, what undo reads), deps.log
(what was installed as whose dependency: why and orphans read it), pins.log, and process.log
(the output of each build and installation).

## Iskra's changes to slpkg
The patch is packages/slpkg/iskra.patch in Iskra's repository:
  1. Signing keys come only from sparkpkg, which imports just the keys whose fingerprints Iskra
     pins (/usr/share/sparkpkg/keys/FINGERPRINTS). Stock slpkg fetches whatever key a mirror
     offers.
  2. Without a terminal (a script, a pipe), its package picker chooses what Enter would, instead
     of stopping with an error.
  3. A package whose signature fails is never installed, even with -y.
  4. Installing a name that is exactly a package's name installs that package, from the first
     repository in priority order that has it. Stock slpkg treats every name as a pattern, so
     asking for acct would also choose every package whose name contains "acct".

## What slpkg does when it installs
  1. Reads the repository's PACKAGES.TXT (names, versions, what each requires) and
     CHECKSUMS.md5, downloaded by slpkg update.
  2. Works out the dependencies, and shows you the list.
  3. Downloads the packages, checks each one's MD5 and its GPG signature (.asc).
  4. Installs them with upgradepkg --install-new: a new package is installed, one that's
     already there is replaced.
For ponce, the one repository of recipes, step 3 downloads the sources a SlackBuild names
instead, checks their MD5s, and builds the package here first (see: slackbuilds).

## Errors you may meet
  a signature doesn't match       nothing is installed. Run sparkpkg sync and try again; if it
                                  still fails, the mirror may be part-way through an update
  a SlackBuild fails to build     its output is on the screen, and in
                                  /var/log/slpkg/process.log

See also: sparkpkg, repositories, pkgtools, slackbuilds ; man slpkg ;
https://dslackw.gitlab.io/slpkg/
