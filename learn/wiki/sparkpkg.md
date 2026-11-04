# sparkpkg: Iskra's packages

Everything on Iskra is a Slackware package: a .txz archive of files, plus a short description
and sometimes a script to run after installing. Slackware's own tools (installpkg, removepkg,
upgradepkg) put them on and take them off, and they don't track dependencies: a package doesn't say
what else it needs. sparkpkg is the one command that does it all for you:

  sparkpkg install foo            install foo and everything it needs
  sparkpkg remove foo             take it off again
  sparkpkg upgrade                bring the whole system up to date (also: iskra-update)
  sparkpkg search word            look for software everywhere sparkpkg can get it
  sparkpkg info foo               what foo is, and where it would come from
  sparkpkg undo                   take back the last install, upgrade or removal
  sparkpkg history                what changed, and when
  sparkpkg help                   all of it; sparkpkg tools: Slackware's own tools, explained

It asks for your password itself (sudo) when it needs to, and asks before it changes anything.
Add -y to answer yes to everything.

## Where packages come from

sparkpkg is built on slpkg, the Slackware package manager that reads several repositories
(collections of packages) at once and works out dependencies. Iskra sets it up to look in this
order, and it takes a package from the first place that has it:

  slack         Slackware -current itself: the system, the kernel, Firefox, mc, NetworkManager...
  slack_extra   Slackware's extras
  iskra         Iskra's own: the desktop, ly, WebCord, Proton VPN, the Russian voices...
  alien         AlienBOB's packages: LibreOffice, Chromium, Wine...
  multilib      AlienBOB's 32-bit libraries, for Steam and Wine
  restricted    AlienBOB's packages with patent-encumbered codecs
  conraid       conraid's packages: fastfetch, TLP and many more
  ponce         SlackBuilds (recipes) for -current: built here, from source, only when no
                one above has a ready-made package

All of them except ponce are ready-made packages, signed by the people who made them, and sparkpkg
checks every signature before installing. The list, and its order, is in
/etc/slpkg/repositories.toml.

## When no one has packaged it: Arch and the AUR

Arch Linux packages a great deal, and its AUR (Arch User Repository) holds recipes for almost
everything else. Their recipes, called PKGBUILDs, are short shell scripts: where to download the
source, and how to build and install it. sparkpkg can follow those recipes on Slackware, and
turn what they make into Slackware packages. When you ask for something Slackware's repositories
don't have, sparkpkg install does this by itself; to choose it yourself:

  sparkpkg aur foo                build and install foo from the AUR
  sparkpkg arch foo               the same, from Arch's own recipe
  sparkpkg convert foo            only fetch foo's recipe and write its SlackBuild, to read first

What it does, in order:
  1. Reads foo's recipe and every dependency it lists, and finds each one: a Slackware package
     of the same name, or one holding the same libraries and programs (Arch calls things
     differently sometimes: its gtk3 is Slackware's gtk+3), or else Arch's or the AUR's recipe
     for it, which it works through in turn.
  2. Shows you the plan: what comes from Slackware, what will be built, in what order.
  3. Installs the Slackware packages through slpkg.
  4. For each recipe from the AUR, offers to show you its PKGBUILD first. Anyone can upload to
     the AUR, so read it if you don't know it: a recipe can do anything a script can.
  5. Builds it as an ordinary user (sparkpkg), not as root, under fakeroot: the recipe never
     has root's power. Then it makes a Slackware package of it, tagged _aur or _arch, and
     installs that through slpkg, so sparkpkg undo can take it back like anything else.
  6. Offers to remove anything that was only needed to build.

Things Arch does that Slackware doesn't, and what sparkpkg does instead:
  systemd services      left out: Iskra starts services with scripts in /etc/rc.d. sparkpkg
                        tells you when a package came with one, so you know to write one
  sysusers.d, tmpfiles.d  the users, groups and folders they ask for are made when the
                        package is installed
  backup=() files       installed as file.new, so your own edited copy is never overwritten
  .install hooks        run after installing, as Arch would
  /usr/lib              Arch keeps libraries there, Slackware in /usr/lib64; Iskra looks in both

Packages built this way are kept in /var/cache/sparkpkg/packages, and their recipes in
/var/lib/sparkpkg/recipes/NAME. sparkpkg upgrade checks the AUR and Arch for newer recipes, and
rebuilds them.

If a dependency can't be found, sparkpkg says which, and stops before building anything. If
Slackware has it under another name, tell sparkpkg in /etc/sparkpkg/names.tsv:

  # Arch name     Slackware name
  libfoo          foo-libs

## Slackware's own tools

sparkpkg uses these, and so can you:
  installpkg file.txz             install a package file
  upgradepkg file.txz             replace the installed package with this one
  removepkg name                  remove an installed package
  ls /var/lib/pkgtools/packages   every installed package; each file lists what it installed
  sh foo.SlackBuild               build a package from a SlackBuild (a recipe), as root
