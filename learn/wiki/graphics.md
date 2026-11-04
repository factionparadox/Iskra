# Graphics (Intel)

The Framework 13 Pro's Intel graphics need no drivers beyond what is installed: the kernel's
xe/i915 driver does the work, Xorg's built-in modesetting driver draws the screen, and Mesa
provides OpenGL and Vulkan.

## What is installed
  mesa                        Mesa 26: OpenGL (iris) and Vulkan (anv), Slackware's own
  libva, intel-media-driver   VA-API video decoding and encoding (the "iHD" driver, for Intel
                              graphics from 2020 on). LIBVA_DRIVER_NAME=iHD is set in
                              /etc/profile.d/iskra.sh
/etc/X11/xorg.conf.d/30-iskra.conf chooses modesetting with TearFree (no tearing in video),
and sets the touchpad and keyboard. xf86-video-intel, the old Intel X driver, is not used: it
does not support recent chips well. X's log is /var/log/Xorg.0.log, or
~/.local/share/xorg/Xorg.0.log when X runs as you.

## Video decoding (battery life)
Decoding video on the GPU instead of the processor saves a lot of power.
  mpv --hwdec=auto FILE                      watch the line "Using hardware decoding (vaapi)"
mpv does this by default here (~/.config/mpv/mpv.conf: hwdec=auto-safe). In Firefox,
about:support, section Media, shows whether hardware decoding is in use; Iskra's policy
(/etc/firefox/policies/policies.json) switches media.ffmpeg.vaapi.enabled on.

## Looking
Some of these may not be installed; sparkpkg search finds them:
  vainfo (libva-utils)                       what the GPU can decode (H.264, HEVC, VP9, AV1)
  glxinfo -B (mesa-utils or mesa-demos)      the OpenGL renderer and version
  vulkaninfo --summary (vulkan-tools)
  intel_gpu_top (intel-gpu-tools)            how busy the GPU is, live (sudo)
  xrandr                                     the screen and its modes (installed)
DPI: 144 (Xft.dpi in /etc/iskra/Xresources), for the 13 Pro's 2880x1920 screen; set your own
in ~/.Xresources.

See also: kernel, firmware ; man modesetting ; man xorg.conf ; man xrandr
