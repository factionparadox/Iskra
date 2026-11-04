# Users, sudo and trust

You are in the wheel group, so sudo works with your password (/etc/sudoers.d/iskra); the
root account has the same password, for recovery from a console. Suspend, hibernate, reboot
and power off need no password, so the menu, Super+z and the lid work. Other groups give you
hardware without sudo: audio, video, input, plugdev (USB drives), netdev (networks). Accounts
are ordinary: useradd, passwd, usermod, and /etc/passwd, /etc/group and /etc/shadow are the
real files.

## Automatic login
If you chose it, ly (the login screen on tty1) logs you in at boot: auto_login_user and
auto_login_session in /etc/ly/config.ini. The screen still locks with your password on sleep,
lid close and Super+x (xss-lock + slock), so a stolen sleeping laptop is locked, but a stolen
powered-off one boots to your desktop. To turn it off, delete those two lines from
/etc/ly/config.ini (sudoedit). Without disk encryption, anyone with the laptop can read the
disk anyway: Iskra does not encrypt it (yet). The fingerprint reader can stand in for your
password with sudo (iskra-fingerprint); the login screen and the screen lock keep to passwords.

## Software
Packages come ready-made, and every one from a binary repository (Slackware's, Iskra's,
AlienBOB's, conraid's) is signed by whoever made it: slpkg checks each signature before
installing, against keys Iskra pins by fingerprint (/usr/share/sparkpkg/keys/FINGERPRINTS),
and Iskra's slpkg refuses a package whose signature fails. Ponce's SlackBuilds aren't signed
packages: slpkg checks every source they download against its MD5. Recipes sparkpkg takes from Arch
and the AUR are checked against their own checksums and built as an ordinary user, never as
root; an AUR recipe can be written by anyone, so sparkpkg offers to show it to you first. The
Russian material is checked against published or pinned checksums.

## Network
The firewall is nftables: /etc/rc.d/iskra-firewall, started by rc.iskra at boot, loads
/etc/nftables.d/iskra.nft. Everything coming in is dropped unless it answers something this
laptop asked for (plus loopback, ICMP and mDNS); everything going out is allowed. The tutor
(llama-server) and the dictionary server (kiwix-serve) listen on 127.0.0.1, this computer
only. openssh is installed (ssh, to reach other computers), but Iskra switches off its server,
sshd, when it's first installed: Slackware starts it when /etc/rc.d/rc.sshd is executable, and
Iskra takes that away. To let other computers ssh in:  sudo chmod +x /etc/rc.d/rc.sshd ; then
sudo /etc/rc.d/rc.sshd start, and open port 22 in /etc/nftables.d/iskra.nft (the firewall drops
it otherwise). Upgrades leave your choice alone.

    sudo nft list ruleset             the firewall as it is now
    ss -tlnp                          what is listening
    id                                your groups

References: man sudo ; man nft ; man useradd ; iskra-learn wiki users
