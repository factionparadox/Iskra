# Искра wiki: Slackware, explained

A reference for the system under Iskra, in the manner of the Arch Wiki: what each part is,
how Slackware does it, the files and commands, and worked examples. The lessons
(iskra-learn learn) are the short guided tour; this is where to look things up.

Read a page:      iskra-learn wiki rc
Search all pages: iskra-learn search hibernate
In acme or mc:    the pages are plain text in /usr/share/iskra/learn/wiki/

## Coming from Arch
  from-arch       pacman, systemctl, journalctl, mkinitcpio, the AUR: the Slackware equivalents

## The system
  system-files    /etc/inittab, /etc/fstab, rc.local, HOSTNAME: the files that are the system
  rc              init and services: rc.S, rc.M, rc.local, the rc.d scripts, rc.iskra
  logging         syslog, /var/log/messages, dmesg
  sleep           suspend and hibernate: iskra-sleep, elogind, the lid
  boot            UEFI, GRUB, the kernel command line, microcode, initrd or none
  kernel          Slackware's kernel-generic, old kernels, modules
  users           accounts, groups and what each allows, sudo, PAM, the fingerprint reader
  locale          locales, the keyboard layout, console font, time zone
  time            chrony and the clock; crond

## Packages
  sparkpkg        Iskra's package manager: install, remove, upgrade, undo, Arch and the AUR
  slpkg           what sparkpkg runs underneath, its settings, keeping a package as it is
  repositories    slack, iskra, alien, conraid, ponce...: the order, signatures and keys
  pkgtools        installpkg, upgradepkg, removepkg, makepkg, pkgtool; .new files
  slackbuilds     how a package is built: SlackBuilds, .info files, Ponce's, Iskra's own
  iskra-tools     Iskra's own: iskra-update, iskra-handbook, iskra-fingerprint, iskra-sleep...

## Hardware and devices
  framework       this laptop: what it needs, what Iskra sets for it and why, known issues
  filesystems     fstab, XFS, TRIM, USB drives, exFAT/NTFS
  network         NetworkManager, DNS, Wi-Fi, VPN, the nftables firewall
  sound           PipeWire and WirePlumber without systemd
  graphics        Intel: Mesa, VA-API video decoding, Vulkan
  firmware        kernel-firmware, microcode, framework_tool
  handbook        the Slackware book, offline (iskra-handbook)

Every page ends with its sources: the Slackware book (offline: iskra-handbook), the manual
pages and upstream documentation. When a page and a manual disagree, the manual is right;
please fix the page.
