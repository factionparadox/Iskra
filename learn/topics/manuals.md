# Handbooks and manual pages: learning on your own

- The Slackware book, offline: iskra-handbook (less /usr/share/doc/slackbook/slackbook.txt).
  "Slackware Linux Essentials" covers the whole system for a newcomer: the shell, users and
  permissions, filesystems, networking, X, package management, updates, the kernel. In less:
  / searches, n finds the next match, q quits. iskra-handbook mc opens it in Midnight
  Commander beside the Iskra wiki; iskra-handbook notes shows Slackware -current's ChangeLog.
  The web version: https://docs.slackware.com/slackbook:start
- man: every command's manual. Sections: 1 commands, 5 file formats, 8 administration.
      man installpkg ; man upgradepkg ; man slpkg ; man 5 fstab ; man 8 nft
      man -k bluetooth   (or apropos bluetooth): search the manuals
- SlackBuilds: how a package was built, as a short shell script, worth reading. Ponce's are at
  https://github.com/Ponce/slackbuilds (branch current), with a README for each on
  https://slackbuilds.org/; Iskra's own in packages/ in Iskra's repository.
- /usr/doc/NAME-VERSION: each package's own README, changes and licence.
- 9 man: Plan 9's own manuals (9 man acme).
- iskra-learn: these lessons; explain shows which lesson and manual cover a command.
- iskra-learn wiki: the Iskra wiki, Slackware explained page by page (rc, system-files,
  sparkpkg, slpkg, repositories, pkgtools, slackbuilds, sleep, boot, from-arch ...).
  iskra-learn search WORD searches the lessons and the wiki together.

## A way to learn something new
1. Read the lesson for the idea (iskra-learn learn services).
2. Read the wiki page for the detail (iskra-learn wiki rc).
3. Look at the real thing (iskra-learn doctor; ls -l /etc/rc.d; less /etc/inittab).
4. Read Slackware's own account (iskra-handbook, then / and a word).
5. Read the manual for the exact options (man installpkg), or the script itself
   (less /etc/rc.d/rc.M).
6. iskra-learn explain "sudo /etc/rc.d/rc.bluetooth restart" to check before running.
7. Change one thing, and know how to undo it: keep a copy of the file you change, and for
   packages, sudo sparkpkg undo.

Ctrl+Super+Space -> Learn the system has all of these.
