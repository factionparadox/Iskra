;;; Avalon's system: what makes Guix System into Avalon. A config.scm uses it like this:
;;;
;;;   (use-modules (gnu) (nongnu packages linux) (nongnu system linux-initrd) (avalon system))
;;;   (operating-system
;;;     (kernel linux) (initrd microcode-initrd) (firmware (list linux-firmware))
;;;     ...your host name, users, file systems, bootloader...
;;;     (packages (append %avalon-packages %base-packages))
;;;     (services %avalon-services))
;;;
;;; Avalon's installer writes exactly that when you choose "Avalon: the Garden System".
;;;
;;;   %avalon-services   Guix's desktop services, without GDM, plus:
;;;                        greetd on tty7 with the Garden System's login screen (in cage)
;;;                        Bluetooth; the Nix daemon (for Metamelayer)
;;;                        Avalon's channels (Guix, Nonguix, Avalon) and Nonguix's substitutes
;;;                        Mango's settings in /etc/mango; the Garden System in /etc/xdg
;;;                        large type on the consoles (Terminus 16x32: the screen is 2880 x 1920)
;;;                        the battery charge limit chosen in Avalon Control, at every boot
;;;   %avalon-packages   Mango, the Garden System, Quickshell, kitty, Firefox, Neredy's
;;;                      llama.cpp (Vulkan) and Piper, Flatpak and its portals, fonts...
;;;   %avalon-channels   what /etc/guix/channels.scm lists, so guix pull keeps all three
(define-module (avalon system)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (gnu services xorg)
  #:use-module (gnu services nix)
  #:use-module (gnu services shepherd)
  #:use-module (gnu packages fonts)
  #:use-module (guix channels)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1)
  #:use-module (avalon packages)
  #:export (%avalon-channels
            %avalon-packages
            %avalon-services
            %nonguix-signing-key))

(define %nonguix-channel
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix")
    (introduction
     (make-channel-introduction
      "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
      (openpgp-fingerprint
       "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))

(define %avalon-channel
  (channel
    (name 'avalon)
    (url "https://github.com/factionparadox/Iskra")
    (branch "main")))

(define %avalon-channels
  (cons* %avalon-channel %nonguix-channel %default-channels))

(define %nonguix-signing-key
  (plain-file "nonguix.pub" "
(public-key
 (ecc
  (curve Ed25519)
  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

(define %avalon-packages
  (cons* mangowm/avalon
         avalon-garden
         (specifications->packages
          (list
           ;; the Garden System's parts
           "quickshell" "kitty" "fastfetch" "cage" "wlsunset" "brightnessctl"
           "wl-clipboard" "grim" "slurp" "swappy" "libnotify" "xorg-server-xwayland"
           "pipewire" "wireplumber" "mpv"
           ;; Firefox, from Nonguix
           "firefox"
           ;; Neredy: the model runs on llama.cpp (Guix's ggml has Vulkan), she speaks with Piper
           "llama-cpp" "python-piper-tts" "python" "curl" "mesa" "vulkan-loader"
           ;; Flatpak, for the few things only made that way (Sober)
           "flatpak" "xdg-desktop-portal" "xdg-desktop-portal-wlr" "xdg-desktop-portal-gtk"
           ;; type: the HUD's DejaVu, the element glyphs (土水風火) and Cyrillic, emoji
           "font-dejavu" "font-google-noto" "font-google-noto-sans-cjk" "font-google-noto-emoji"
           ;; HECTAS and Metamelayer are Guile; nmtui comes with NetworkManager
           "guile" "network-manager" "nano"))))

(define garden-greeter
  ;; the Garden System's login screen: Quickshell in cage, as the greeter user
  (program-file "garden-greeter"
    #~(execl #$(file-append (specification->package "cage") "/bin/cage")
             "cage" "-s" "--"
             #$(file-append (specification->package "quickshell") "/bin/quickshell")
             "-p" #$(file-append avalon-garden "/share/garden/greeter.qml"))))

(define (avalon-etc-files)
  ;; Mango's settings and the Garden System's, where they look for them
  `(("mango/config.conf" ,(file-append avalon-garden "/etc/mango/config.conf"))
    ("xdg/quickshell/garden" ,(file-append avalon-garden "/etc/xdg/quickshell/garden"))
    ("xdg/kitty/kitty.conf" ,(file-append avalon-garden "/etc/xdg/kitty/kitty.conf"))
    ("xdg/fastfetch/config.jsonc" ,(file-append avalon-garden "/etc/xdg/fastfetch/config.jsonc"))))

(define charge-limit-service
  ;; Avalon Control's battery charge limit (sudo avalon-power charge-limit N), at every boot
  (simple-service 'avalon-charge-limit shepherd-root-service-type
    (list (shepherd-service
            (provision '(avalon-charge-limit))
            (requirement '(file-systems))
            (one-shot? #t)
            (documentation "Apply the battery charge limit chosen in Avalon Control.")
            (start #~(lambda _
                       (when (file-exists? "/etc/avalon/charge-limit")
                         (system* #$(file-append avalon-garden "/sbin/avalon-power")
                                  "charge-limit"
                                  (call-with-input-file "/etc/avalon/charge-limit"
                                    (@ (ice-9 rdelim) read-line))))
                       #t))))))

(define %avalon-services
  (cons*
   (service greetd-service-type
            (greetd-configuration
             (greeter-supplementary-groups (list "video" "input"))
             (terminals
              (list (greetd-terminal-configuration
                     (terminal-vt "7")
                     (terminal-switch #t)
                     (default-session-command garden-greeter))))))
   (service bluetooth-service-type)
   (service nix-service-type)
   (simple-service 'avalon-etc etc-service-type (avalon-etc-files))
   charge-limit-service
   (modify-services
       (remove (lambda (s) (eq? (service-kind s) gdm-service-type))
               %desktop-services)
     (guix-service-type
      config => (guix-configuration
                 (inherit config)
                 (channels %avalon-channels)
                 (substitute-urls
                  (append (guix-configuration-substitute-urls config)
                          '("https://substitutes.nonguix.org")))
                 (authorized-keys
                  (cons %nonguix-signing-key
                        (guix-configuration-authorized-keys config)))))
     (console-font-service-type
      config => (map (lambda (tty)
                       (cons (car tty)
                             (file-append font-terminus "/share/consolefonts/ter-132n")))
                     config)))))
