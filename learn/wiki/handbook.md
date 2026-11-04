# The Slackware book, offline

"Slackware Linux Essentials", the Slackware book, is the guide written for Slackware by Alan
Hicks, Chris Lumens, David Cantrell and Logan Johnson: the shell, users and permissions,
filesystems, networking, the X Window System, package management, keeping up with updates and
building a kernel. It is written for newcomers, and the rest of Slackware assumes you know what
it says. Its current copy lives on the Slackware documentation wiki,
https://docs.slackware.com/slackbook:start, one chapter a page, and Iskra keeps it offline as a
single text file: /usr/share/doc/slackbook/slackbook.txt. iskra-update fetches it again each
time, so it stays current.

Some of it is older than Iskra's way of doing things: it boots with LILO, where Iskra uses GRUB
on UEFI (see: boot), and it installs from Slackware's own installer, where Iskra has
iskra-install. Everything about the shell, the files and the package tools still holds.

## Reading it
  iskra-handbook            the book in less (also in the menu's Learn list)
  iskra-handbook mc         Midnight Commander with this wiki on one side and the book's
                            folder on the other
  iskra-handbook notes      Slackware -current's ChangeLog: every change, newest first, with
                            Patrick Volkerding's notes on the big ones
  iskra-handbook update     fetch the newest book and ChangeLog now (needs the internet)
  less /usr/share/doc/slackbook/slackbook.txt     the same, in any terminal

less's keys:
  Space / b                   next and previous page
  /word, then n / N           search, next and previous match
  g / G                       the start / the end
  q                           quit

Searching is the quickest way in: /installpkg, /inittab, /rc.M, /fstab ...

## How it is fetched
iskra-handbook update reads the book's contents page (slackbook:start, as raw text) for the
chapters and their order, fetches each chapter as plain HTML (?do=export_xhtml), and
/usr/lib/iskra/handbook-text turns them into one text file: headings, paragraphs, lists and the
command examples exactly as they are. If the site can't be reached, or what comes back doesn't
look like the whole book, the offline copy stays as it was. The ChangeLog comes from a Slackware
mirror (slackware.uk) and is kept beside it, as ChangeLog.txt.

## The manual pages
The book explains; the manual pages give every option:
  man installpkg ; man upgradepkg ; man removepkg ; man makepkg ; man explodepkg ; man pkgtool
  man slpkg ; man init ; man inittab ; man fstab

## Online
  https://docs.slackware.com/          SlackDocs: the book, and HOWTOs written by Slackware's
                                       users on much more than the book covers
  https://www.slackware.com/           Slackware itself
  https://www.linuxquestions.org/questions/slackware-14/   the Slackware forum, where its
                                       developers answer too
  https://slackbuilds.org/             SlackBuilds, with a README for each (see: slackbuilds)

## Where it fits
The book says how Slackware is meant to be used; this wiki explains the same system at shorter
length, with Iskra's own choices; the lessons (iskra-learn learn) are the short tour. When they
disagree, the manual pages are right.

See also: index ; man less
