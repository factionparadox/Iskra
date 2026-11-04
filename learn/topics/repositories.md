# Repositories: where the software comes from

A repository is a collection of ready-made packages on a web server, with a list of them
(PACKAGES.TXT: names, versions, descriptions, what each requires), their checksums and a
signature for each. slpkg reads several at once, and sparkpkg looks in them in this order
(/etc/slpkg/repositories.toml, PRIORITY under [ALL_REPOS]: the first one that has a package
wins):
    slack        Slackware64 -current itself: the system, the kernel, Firefox, mc, NetworkManager
    slack_extra  Slackware's extras
    iskra        Iskra's own: ly, ratpoison, polybar, X-терминал, the desktop, sparkpkg, the
                 Russian kit, WebCord, FreeTube, Proton VPN ...
    alien        AlienBOB's: LibreOffice, Chromium, Wine ...
    multilib     AlienBOB's 32-bit libraries (Steam, Wine)
    restricted   AlienBOB's packages with patent-encumbered codecs
    conraid      conraid's: fastfetch, TLP, neovim, fzf and many more
    ponce        Ponce's SlackBuilds for -current: recipes, built here, only when no one above
                 has a ready-made package

## Updating them
    sudo sparkpkg sync               fetch every repository's latest lists
    iskra-update                     sync, then upgrade everything
sync only changes the lists; nothing is installed until you upgrade or install.

## Trust
Every package in every repository but ponce is signed by the people who made it, and slpkg
checks the signature before installing; Iskra's slpkg refuses a package whose signature fails.
The keys it checks against are the ones Iskra pins, with their fingerprints, in
/usr/share/sparkpkg/keys/FINGERPRINTS: Slackware's, AlienBOB's (alien, multilib and
restricted), conraid's, and Iskra's own. Ponce's SlackBuilds aren't packages: slpkg checks the
MD5 of every source they download, then builds it. Recipes sparkpkg takes from Arch and the AUR
are checked against the checksums in the recipe, and the AUR's are shown to you first.

## Look
    sparkpkg info firefox            which repository a package would come from
    grep -A3 '^\[ALL_REPOS\]' /etc/slpkg/repositories.toml
    cat /usr/share/sparkpkg/keys/FINGERPRINTS
    iskra-handbook notes             Slackware -current's ChangeLog: what changed, and why

References: man slpkg ; iskra-learn wiki repositories ; iskra-learn wiki sparkpkg
