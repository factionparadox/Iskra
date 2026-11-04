# Network and Bluetooth

NetworkManager manages Wi-Fi, Ethernet (USB-C dongles, docks) and VPNs; it drives
wpa_supplicant itself, so nothing fights over the card. It is Slackware's
/etc/rc.d/rc.networkmanager, which rc.M starts after D-Bus; Slackware's other network script,
rc.inet1, is left with nothing to configure. The Framework's Wi-Fi 7 card needs a new kernel
and its firmware: Slackware -current's kernel-generic and kernel-firmware have both.

## Use
    Ctrl+Super+n                      networkmanager_dmenu: networks and VPNs in a dmenu list
    nmtui                             the same in a terminal (the menu's "Wi-Fi (full screen)")
    nmcli device wifi list ; nmcli device wifi connect NAME --ask
    nmcli connection show             saved networks

## VPN
Ctrl+Super+p opens the Proton VPN app (Iskra's proton-vpn-gtk-app package); sign in once, and it
keeps the login in gnome-keyring. It sets up its connections through NetworkManager
(WireGuard or OpenVPN).
Without the app, any WireGuard file works: NetworkManager runs WireGuard itself (it is in the
kernel). Give the file a short name (it becomes the interface: 15 characters at most):
    nmcli connection import type wireguard file ~/Downloads/proton-uk.conf
Then the menu's "VPN on/off (WireGuard files)" (iskra-vpn) switches it, or:
    nmcli connection up id proton-uk ; nmcli connection down id proton-uk
It stays off at boot unless you ask:  nmcli connection modify proton-uk autoconnect yes

## Look
    ip -br addr ; ip route ; ping -c 3 slackware.com
    iw dev                            the Wi-Fi card
    sudo /etc/rc.d/rc.networkmanager status
    sudo nft list ruleset             the firewall (iskra-learn learn security)

## Bluetooth
bluetoothd is the service (/etc/rc.d/rc.bluetooth, from Slackware's bluez). Ctrl+Super+b opens
bluetuith, a menu in the terminal: pair, connect, trust, with the arrow keys. bluetoothctl is
there too (the menu's "Bluetooth (bluetoothctl)"):
    power on ; scan on ; pair XX:XX:... ; connect XX:XX:... ; trust XX:XX:...

References: man nmcli ; man nmtui ; iskra-learn wiki network
