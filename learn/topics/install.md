# What the installer did

Iskra's install stick is a Slackware Live system, made with liveslak (AlienBOB's Slackware Live
builder): the whole of Iskra, ready to run from the stick, with a live user (live, password
live). The installer, sudo iskra-install, asked five questions (the disk, a computer name, your
username and password, the timezone, whether to log in automatically), then one Yes/No, and
then copied that system to the disk. Nothing was downloaded and nothing compiled: it takes a
few minutes. Its log is /var/log/iskra-install.log: every command it ran, with its output.

## The steps, as commands
1. Partitions (GPT, sfdisk): 1 GiB EFI (FAT32), swap the size of your RAM, XFS for the rest
       mkfs.fat -F 32 -n EFI /dev/nvme0n1p1 ; mkswap -L swap /dev/nvme0n1p2
       mkfs.xfs -f -L Iskra /dev/nvme0n1p3
   (on a disk too small for that much swap, there is no swap partition and no hibernation)
   Then the root at /mnt/iskra-target, the EFI partition at /mnt/iskra-target/boot/efi.
2. The system: everything on the stick except its live session, copied across with
       rsync -aHAX --numeric-ids
3. Your settings: /etc/fstab (by UUID), /etc/HOSTNAME and /etc/hosts, the timezone
   (/etc/localtime) with the hardware clock on UTC, British English (LANG=en_GB.UTF-8 in
   /etc/profile.d/lang.sh) and a British keyboard on the console (rc.keymap) and in X, your
   account (in wheel, audio, video, input, plugdev, power, netdev and a few more) and the
   password, hashed, for you and root; your home folder from /usr/share/iskra/skel; ly's
   settings (automatic login, if you chose it).
   Then GRUB, with Iskra's theme: grub-install twice (as "Iskra", and at the fallback path),
   and grub-mkconfig. The kernel line gets quiet and resume= (for hibernation), and the root
   is named by its PARTUUID, so no initrd is needed. Only if GRUB had named it by its UUID
   would the installer have made one, with Slackware's mkinitrd.

If it stopped part-way, nothing on the disk is worth keeping: start the stick again and run
sudo iskra-install once more. What went wrong is in /tmp/iskra-install.log on the stick.

## After the first boot
    sudo sparkpkg install libreoffice      LibreOffice, ready-made from AlienBOB
    iskra-update                           anything newer since the stick was made
    iskra-fingerprint                      use your finger for sudo
Secure Boot stays off (hibernation needs it off).

## See the result
    cat /etc/fstab ; lsblk -f
    ls /var/lib/pkgtools/packages | wc -l
    less /var/log/iskra-install.log

Reference: iskra-handbook (the Slackware book's installation chapter covers Slackware's own
installer, which does the same steps by hand)
