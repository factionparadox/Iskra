# Battery, heat, sleep and hibernation

Iskra keeps the laptop idle as much as possible: ratpoison and polybar barely use the CPU,
no compositor redraws the screen, and services are few. Then:
- tlp (/etc/rc.d/rc.tlp, started by rc.iskra) tunes the hardware for battery when unplugged,
  with its defaults: the CPU's energy policy goes to "power" and the platform profile to
  "low-power" (on the charger: balance_performance and balanced); Wi-Fi and USB power saving
  on battery.
- thermald (adaptive mode) keeps the CPU cool without fans racing, and intel_lpmd, Intel's
  low-power daemon, keeps light work on the chip's low-power cores; rc.iskra starts both.
- on battery the screen runs at 60 Hz instead of 120 and blanks after 5 minutes instead of 10
  (iskra-battery switches both when you plug in or unplug).
- video is decoded by the GPU, not the processor: mpv (~/.config/mpv/mpv.conf: hwdec=auto-safe)
  and Firefox (VA-API, switched on in /etc/firefox/policies/policies.json).
- Wi-Fi power saving stays on: NetworkManager would otherwise reset what tlp sets
  (/etc/NetworkManager/conf.d/50-iskra-wifi-powersave.conf).
- Firefox offers uBlock Origin on first start (the same policies file): adverts and trackers
  are much of what keeps the processor busy on the web.
- the tutor (llama-server) uses no processor while idle, but keeps its model in memory while
  it runs: sudo /etc/rc.d/iskra-tutor stop frees it until the next boot.
Swap is the disk partition only (no zram).

## Sleep
acpid (/etc/rc.d/rc.acpid) catches the lid and the power button and runs iskra-sleep as root
(its rules: /etc/acpi/events/iskra-lid and iskra-power; elogind is told to leave both alone).
Closing the lid suspends; on battery, with a swap partition to hibernate into, it also sets the
clock to wake the laptop after two hours asleep, and then hibernates it: memory goes to disk
and it switches off completely, so a forgotten laptop does not drain flat. On the charger the
lid only suspends; the power button suspends too. The battery watcher (iskra-battery) warns at
15 % and 7 % and hibernates at 4 %. Each one locks the screen first.

    iskra-sleep suspend ; iskra-sleep hibernate     (Super+z suspends; Super+Escape is
                                                        the power menu; no password needed)
    iskra-sleepcheck                                  is that sleep the deep kind? (below)

## Measure, don't guess
    sudo tlp-stat -b ; sudo tlp-stat -s   battery health; tlp's state
    cat /sys/class/power_supply/BAT1/capacity
    cat /sys/firmware/acpi/platform_profile
sudo powertop (the System menu's battery report) shows what is using power, process by process.

## More, if you want it (each one costs something)
tlp's settings are /etc/tlp.conf (or a file of your own in /etc/tlp.d/); after a change,
sudo /etc/rc.d/rc.tlp restart. For example:
  CPU_BOOST_ON_BAT=0               no turbo on battery: cooler and longer-lasting, but
                                   noticeably slower (the AI tutor especially)
  sudo framework_tool --charge-limit 80   stop charging at 80 %: a longer-lived battery
  a dimmer screen                  the screen is the largest single draw: brightness keys
Avoid a second power manager (power-profiles-daemon, auto-cpufreq) beside tlp: they fight over
the same settings.

## Is sleep really asleep?
    iskra-sleepcheck               suspends for a minute, then says how much of it the chip
                                     spent in its deepest state (S0ix). Near 100 % is right;
                                     near 0 % means something keeps it awake all night
Also in the menu: System -> Sleep check.

## Not here
Expansion cards you rarely use can come out.

References: man tlp ; man acpid ; iskra-learn wiki sleep
