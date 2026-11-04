# Users, groups and sudo

## Accounts
Accounts are the ordinary files: /etc/passwd, /etc/group and /etc/shadow, changed with the
ordinary tools. The installer made yours with
  useradd -m -g users -s /bin/bash \
    -G wheel,audio,video,input,plugdev,power,netdev,lp,cdrom,scanner YOU
and set your password and root's to the one you gave (hashed, in /etc/shadow).
  passwd ; sudo passwd root         change a password
  id ; groups                       who you are, your groups
  sudo useradd -m -g users -G audio,video,input,plugdev,netdev,power -s /bin/bash anna
  sudo passwd anna                  another account (add wheel for sudo)
  sudo usermod -aG GROUP YOU        join a group (log in again for it to count)
New accounts get their home from /etc/skel; Iskra's desktop files are in
/usr/share/iskra/skel:  sudo cp -rn /usr/share/iskra/skel/. /home/anna/ ; then chown -R.
Slackware also has adduser, which asks for each detail in turn.

## What the groups are for
  wheel       may use sudo
  audio       access to sound devices
  video       access to video devices (the GPU, the webcam, the backlight)
  input       input devices: /dev/input/event* (some tools read keyboards directly)
  plugdev     mount USB drives and SD cards through udisks (a polkit rule of Slackware's)
  netdev      change network connections in NetworkManager (likewise)
  power       sleep, restart and power off through polkit (Slackware's rules for elogind
              and upower)
  lp, cdrom, scanner   printers, optical drives, scanners
  users       the ordinary users' group

## sudo
  sudo COMMAND                 run as root (asks your password, then remembers it a while)
  sudo -i                      a root shell (exit to leave)
  sudo visudo -f /etc/sudoers.d/NAME     a rule of your own, checked before it is saved
/etc/sudoers.d/iskra:
  %wheel ALL=(ALL:ALL) ALL
  %wheel ALL=(root) NOPASSWD: /usr/bin/iskra-sleep, /sbin/reboot, /sbin/poweroff
so sleeping, restarting and powering off need no password (the menu and Super+z rely on it).
The root password is yours, for recovery from a console.

## PAM
PAM (Pluggable Authentication Modules) decides how a program checks who you are; its files
are /etc/pam.d/NAME, one per program, most of them including /etc/pam.d/system-auth. The ones
that matter here:
  ly                the login screen (with automatic login, ly logs you in without asking)
  login             the text login on the consoles; its pam_elogind line registers your
                    session with elogind and makes /run/user/UID (see: sleep)
  sudo, polkit-1    where iskra-fingerprint adds the fingerprint reader (below)
  slock             is setuid root and checks your password itself, through /etc/shadow

## The fingerprint reader
fprintd and libfprint drive the Framework's reader. iskra-fingerprint enrols a finger and adds
pam_fprintd to the top of /etc/pam.d/sudo and /etc/pam.d/polkit-1, so sudo (and programs that
ask through polkit) take a finger first and your password after 10 seconds or Ctrl+C. The login
screen and the screen lock keep to passwords. iskra-fingerprint off takes the line out again
(see: iskra-tools).

See also: sleep, system-files, iskra-tools ; man useradd ; man usermod ; man sudo ;
man sudoers ; man pam.d ; man fprintd
