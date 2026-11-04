# Repositories: where Iskra's packages come from

A repository is a folder on a web server: packages (.txz), and beside them PACKAGES.TXT (every
package's name, version, description and what it requires), CHECKSUMS.md5, ChangeLog.txt and a
signature (.asc) for each package. "Updating the package lists" is fetching those lists again;
nothing is installed until you ask (see: slpkg).

## Iskra's repositories, in order
slpkg reads them in the PRIORITY order under [ALL_REPOS] in /etc/slpkg/repositories.toml, and
takes a package from the first one that has it:
  slack         Slackware64 -current: the whole system, the kernel, Firefox, NetworkManager, mc
  slack_extra   the extra folder of Slackware -current
  iskra         Iskra's own: the desktop (ratpoison, polybar, ly, X-терминал...), sparkpkg and
                Iskra's patched slpkg, the Russian kit, WebCord, Proton VPN. Built by GitHub's CI
                from Iskra's repository, ready-made and signed
  alien         AlienBOB's packages: LibreOffice, Chromium, Wine...
  multilib      AlienBOB's 32-bit libraries, for Steam and Wine
  restricted    AlienBOB's packages with patent-encumbered codecs
  conraid       conraid's packages: fastfetch, TLP, neovim, fzf and many more
  ponce         Ponce's SlackBuilds for -current: recipes, not packages, built on this laptop;
                only when no one above has a ready-made package (see: slackbuilds)
Slackware's own come first, so where two repositories have the same package, you get Slackware's.
sparkpkg info foo  says which one a package would come from.

## Signatures and keys
Every package in the binary repositories (all of them but ponce) is signed by the people who
made it, and slpkg checks every signature before installing; Iskra's slpkg refuses a package
whose signature doesn't match, with no question asked (see: slpkg). The keys it checks against
are only the ones Iskra pins:
  /usr/share/sparkpkg/keys/FINGERPRINTS     each repository's key and its fingerprint
  /usr/share/sparkpkg/keys/NAME.asc         the keys themselves
sparkpkg imports a key into root's keyring only if its fingerprint matches the one in
FINGERPRINTS. alien's key also signs multilib and restricted. Ponce's SlackBuilds aren't signed
packages: slpkg checks the MD5 of every source they download instead.

## Updating
  sudo sparkpkg sync               fetch every repository's latest lists (slpkg update)
  sudo sparkpkg upgrade            sync, then upgrade everything (also: iskra-update)
  iskra-update --dry               only show what would change
Slackware -current changes often, sometimes every day; its ChangeLog says what changed and
why (iskra-handbook notes, or https://slackware.uk/slackware/slackware64-current/ChangeLog.txt).

## Changing the list
/etc/slpkg/repositories.toml has a section for each repository slpkg knows: ENABLE = true or
false, and MIRROR. Iskra enables the eight above and lists them in PRIORITY. To use a nearer
mirror of Slackware, change MIRROR under [SLACK] and [SLACK_EXTRA] (it must end with a /), then
sudo sparkpkg sync. To stop using one, set ENABLE = false and take it out of PRIORITY.
A repository of your own (a folder with PACKAGES.TXT, CHECKSUMS.md5 and ChangeLog.txt) goes in
the same file as a new section with ENABLE, MIRROR and TAG: the file's own comments show how.
Its packages need a key in FINGERPRINTS too, or sparkpkg won't install them.

## Packages built from recipes
Packages sparkpkg builds from Arch's and the AUR's recipes (see: sparkpkg) don't come from a
repository at all: they're made here, kept in /var/cache/sparkpkg/packages, and their recipes
in /var/lib/sparkpkg/recipes/NAME. sparkpkg upgrade looks for newer recipes for them.

See also: sparkpkg, slpkg, slackbuilds ; man slpkg ;
https://slackware.uk/slackware/slackware64-current/ ; https://slackware.nl/people/alien/ ;
https://slackers.it/repository/ ; https://github.com/Ponce/slackbuilds
