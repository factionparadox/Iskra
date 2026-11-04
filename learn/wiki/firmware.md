# Firmware and microcode

## Device firmware: kernel-firmware
Many devices load a firmware file from the disk when their driver starts: Intel graphics,
Wi-Fi (iwlwifi), Bluetooth, the audio DSP and more. Slackware's kernel-firmware package has the
whole collection in /lib/firmware, so the Wi-Fi works on the first boot. A missing file shows in
dmesg:
  sudo dmesg | grep -i firmware      ("failed to load" names the file)
  grep -l 'lib/firmware/iwlwifi' /var/lib/pkgtools/packages/*    which package has it
A newer kernel-firmware arrives with iskra-update; it is used from the next boot (or the next
time the driver loads).

## CPU microcode
Intel's corrections to the processor itself, loaded at every boot before anything else (they
do not change the chip permanently). Slackware's intel-microcode package puts them in
/boot/intel-ucode.img, and GRUB loads that file before the kernel (grub-mkconfig adds it to every
menu entry it finds it for). A new version is used from the next boot.
  dmesg | grep -i microcode        "microcode updated early to revision ..."

## The laptop's own firmware
Framework publishes BIOS updates on the LVFS (for fwupd) and as files with their own
instructions:  https://knowledgebase.frame.work/
fwupd isn't part of Slackware; if you install it, the System menu's "Firmware updates" entry
appears and runs  sudo fwupdtool refresh ; sudo fwupdtool get-updates.

## framework_tool
Framework's own tool (from framework-system; Iskra's framework-tool package installs Framework's
release build) talks to the embedded controller. It needs root:
  sudo framework_tool --versions              BIOS, EC and other firmware versions
  sudo framework_tool --power                 battery and charger
  sudo framework_tool --charge-limit 80       stop charging at 80 %
  sudo framework_tool --kblight 50            keyboard light
  sudo framework_tool --touchscreen-enable false
  sudo framework_tool --click-force high      the haptic touchpad's click
The menu's System list has the keyboard light, touchscreen and click force.
framework_tool --help lists the rest.

See also: boot (microcode), kernel, framework, graphics ;
https://github.com/FrameworkComputer/framework-system
