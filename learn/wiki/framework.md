# Framework Laptop 13 Pro (Intel Core Ultra Series 3)

The laptop Iskra is built for: Framework's 2026 redesign of the 13, with Intel's Core Ultra
Series 3 ("Panther Lake") processors.

## This one
  Processor   Core Ultra 5 325: 8 cores (4 performance, 4 low-power efficient), 8 threads,
              up to 4.5 GHz; Intel graphics with 4 Xe cores; an NPU (not used by Iskra)
  Memory      LPCAMM2 LPDDR5X, 6800 MT/s on the Ultra 5 325 (32 GB here)
  Display     13.5", 2880x1920 (3:2, 256 ppi), 30-120 Hz, touch
  Wi-Fi       Intel Wi-Fi 7 BE211 (PCI 8086:e440), driver iwlwifi; Bluetooth on the same card
  Graphics    PCI 8086:b082 (Xe3), kernel driver xe
  Battery     74 Wh
  Touchpad    haptic (no moving parts; the click is a vibration)
Check yours: lscpu ; lspci -nn

## What it needs, and what Iskra sets
  a new kernel      Panther Lake needs a recent one (Framework recommends the newest):
                    Slackware -current's kernel-generic, 7.2.15 (see: kernel)
  firmware          kernel-firmware, and the CPU microcode (intel-microcode), which GRUB
                    loads before the kernel (see: firmware)
  framework_tool    the embedded controller: charge limit, keyboard light, touchscreen,
                    the haptic click force, firmware versions (see: firmware)
  fprintd           the fingerprint reader, for sudo: iskra-fingerprint (see: iskra-tools)
  intel_lpmd        Intel's low-power daemon for these hybrid chips: it keeps light work on the
                    low-power cores (rc.iskra starts it; see: rc)

From nixos-hardware's module for this board (framework/13-inch/intel-core-ultra-series3,
which includes the common Framework 13 and Intel settings), Iskra also sets:
  blacklist cros_usbpd_charger   its USB-C charger driver would wake the laptop
                    (/etc/modprobe.d/iskra-framework.conf, from iskra-desktop)
  TLP               battery tuning (nixos-hardware uses TLP too unless another tuner is on)
nixos-hardware also sets the kernel argument nvme.noacpi=1 (lower SSD power use, also while
suspended); Iskra's installer doesn't. To try it, add it to GRUB_CMDLINE_LINUX_DEFAULT in
/etc/default/grub and remake GRUB's menu (see: boot).

Tools for this laptop (menu: System):
  iskra-sleepcheck    does sleep reach S0ix? (suspends for a minute)
Iskra's own battery settings for this panel and chip (iskra-learn learn power): 60 Hz on
battery (120 on the charger), earlier screen blanking, GPU video decoding in mpv and Firefox,
Wi-Fi power saving kept on.

## Not on Iskra
  fwupd             firmware updates from the LVFS: not part of Slackware (see: firmware)
  iio-sensor-proxy  the ambient light sensor; only GNOME and KDE use it for automatic
                    brightness, and ratpoison has nothing to read it
  framework-laptop-kmod   a community kernel module exposing the EC in /sys; not included
  speaker tuning    nixos-hardware's equaliser preset is for the classic 13's speakers; it says
                    the 13 Pro needs different tuning, and none is published yet
  weekly TRIM       not scheduled (see: filesystems)
  Secure Boot       must stay off: hibernation needs it off

## Known issues (community reports, autumn 2026)
- The haptic touchpad has been reported, rarely, not to come back after sleep. Reloading its
  driver may bring it back (untested on Iskra):
      sudo modprobe -r hid_multitouch && sudo modprobe hid_multitouch
  If it happens often, report it on the Framework community forum with your BIOS version.
- If the battery drops a lot overnight, run iskra-sleepcheck: under 80 % in S0ix means a
  device or driver keeps the chip awake; unplug expansion cards one at a time to find it.
- Text size: Iskra uses 144 dpi (150%). Framework's own guides suggest 200% for this panel;
  for larger text set  Xft.dpi: 192  in ~/.Xresources and log in again (see: graphics).

## Updating the firmware
Framework publishes BIOS updates with their own instructions in their knowledge base
(https://knowledgebase.frame.work/), and on the LVFS for fwupd, if you install it (see:
firmware). Check the result with  sudo framework_tool --versions.

See also: firmware, kernel, graphics, filesystems, sleep (hibernation) ;
https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/intel-core-ultra-series3 ;
https://github.com/FrameworkComputer/linux-docs ; https://frame.work/laptop13pro ;
https://community.frame.work/
