# Files: Midnight Commander

mc (Ctrl+Super+e) shows two folders side by side. Tab switches sides; the function keys along the
bottom are the actions:
    F3 view   F4 edit (mcedit)   F5 copy   F6 move/rename   F7 new folder   F8 delete   F10 quit
    Ctrl+o    hide the panels and use the shell underneath (Ctrl+o again to come back)
    Ctrl+\    a list of favourite folders     Alt+?  find files
    Enter on an archive (.zip, .tar.gz, a .txz package) opens it like a folder.

mcedit, mc's editor, is also the system's EDITOR (/etc/profile.d/iskra.sh): sudoedit, git and
slpkg use it. Ctrl+s or F2 saves, F10 quits. For writing, acme is there too
(iskra-learn learn plan9).

## Look around the system with it
Slackware keeps the usual layout: programs in /usr/bin, libraries in /usr/lib64 (and
/usr/lib, for programs built from Arch's recipes), manual pages in /usr/man, documentation in
/usr/doc. /etc is plain files you can edit; /etc/inittab and /etc/rc.d are the system's
start-up. /var/lib/pkgtools/packages has one file per installed package, listing its files;
grep -l '^usr/bin/mc$' /var/lib/pkgtools/packages/* (the path without its first /) tells you
which package a file belongs to. Logs are in /var/log; your files and settings in your home
folder.

References: man mc ; man mcedit ; https://midnight-commander.org/
