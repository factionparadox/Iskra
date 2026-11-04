# The Framework Laptop 13 Pro

Intel Core Ultra series 3 (Panther Lake), LPCAMM2 memory, NVMe storage, an Intel Wi-Fi 7 card,
Intel audio DSP with SoundWire, and expansion cards (USB-C devices underneath).

What Iskra does for it:
- Slackware -current's kernel-generic, 7.2.15, and kernel-firmware (Wi-Fi, Bluetooth,
  graphics, the audio DSP and the rest).
- Intel's CPU microcode (intel-microcode), which GRUB loads before the kernel.
- Graphics through the modesetting driver without tearing, the touchpad (tap to click, natural
  scrolling, no clicks while typing): both in /etc/X11/xorg.conf.d/30-iskra.conf. Mesa for
  3D and Vulkan, intel-media-driver for video decoding (LIBVA_DRIVER_NAME=iHD).
- The dense screen: 144 dpi (Xft.dpi in /etc/iskra/Xresources; try 120 or 168 in ~/.Xresources).
- framework_tool, Framework's own tool for the embedded controller: touchscreen off, keyboard
  light, touchpad click force, charge limit (menu: System).
- intel_lpmd, Intel's low-power daemon for these hybrid chips, and thermald.
- The fingerprint reader, through fprintd: iskra-fingerprint enrols a finger for sudo.

## Look
    lspci -k ; lsusb                  devices and their drivers
    sudo dmesg | less                 kernel messages since boot
    sudo framework_tool --versions    BIOS and embedded-controller versions
    cat /sys/class/backlight/*/brightness

Secure Boot must be off: hibernation needs it off.

References: https://knowledgebase.frame.work/ ; iskra-learn wiki framework
