;;; Avalon's packages: what Guix doesn't have, or has differently.
;;;   mangowm/avalon   Mango 0.18.5 (Guix has 0.18.3), reading /etc/mango/config.conf as its default
;;;   avalon-garden    the Garden System: the shell's QML, its settings, the greeter, the artwork,
;;;                    and Avalon's commands (avalon, garden, neredy, hectas, metamelayer,
;;;                    avalon-control, avalon-power...), from this repository's desktop/ folder
(define-module (avalon packages)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages python)
  #:use-module (gnu packages window-management))

(define-public mangowm/avalon
  (package
    (inherit mangowm)
    (version "0.18.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/mangowm/mango")
             (commit version)))
       (file-name (git-file-name "mangowm" version))
       (sha256
        (base32 "1jwgdgb85lz533kg818sfd2jz9kbw4sx496s2c6lanxhdh7kwsh7"))))
    (arguments
     (list
      ;; Mango's own config.conf goes in the package; the one it reads when you have none in
      ;; ~/.config/mango is /etc/mango/config.conf, which is the Garden System's (Avalon's
      ;; services put it there). Guix's mangowm reads the package's instead.
      #:configure-flags
      #~(list (string-append "-Dsysconfdir=" #$output "/etc"))
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'install-into-the-package
            (lambda _
              (substitute* "meson.build"
                (("is_nixos = false") "is_nixos = true")))))))))

(define %garden-files
  (local-file "../desktop" "avalon-garden-files" #:recursive? #t))

(define-public avalon-garden
  (package
    (name "avalon-garden")
    (version "1.0")
    (source %garden-files)
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("usr/bin/" "bin/")
          ("usr/sbin/" "sbin/")
          ("usr/share/" "share/")
          ("etc/" "etc/"))
      #:modules '((guix build copy-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1))
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'install 'point-at-the-store
            ;; the files say /usr/share/... (as on any other system); here that's this package
            (lambda _
              (let ((text-files
                     (remove (lambda (f)
                               (any (lambda (ext) (string-suffix? ext f))
                                    '(".png" ".pf2" ".jpg" ".onnx")))
                             (append (find-files "etc") (find-files "usr")))))
                (with-fluids ((%default-port-encoding "UTF-8"))
                  (substitute* text-files
                    (("/usr/sbin/avalon-power") (string-append #$output "/sbin/avalon-power"))
                    (("/usr/share/") (string-append #$output "/share/")))
                  (substitute* '("usr/bin/hectas" "usr/bin/metamelayer")
                    (("exec guile ")
                     (string-append "exec " #$(file-append guile-3.0 "/bin/guile") " ")))))))
          (add-after 'install 'wrap-avalon-control
            ;; GTK 4 and its Python bindings, for Avalon Control
            (lambda _
              (wrap-program (string-append #$output "/bin/avalon-control")
                `("GI_TYPELIB_PATH" ":" prefix (,(getenv "GI_TYPELIB_PATH")))
                `("GUIX_PYTHONPATH" ":" prefix (,(getenv "GUIX_PYTHONPATH")))))))))
    (inputs (list bash-minimal guile-3.0 python python-pygobject gtk gobject-introspection))
    (home-page "https://github.com/factionparadox/Iskra")
    (synopsis "The Garden System: Avalon's desktop")
    (description
     "The Garden System is Avalon's desktop, after the 1999 PlayStation game Pixygarden:
a Quickshell shell (HUD, star system, launcher, Command Mode, notifications, lock), its
greetd login screen, Mango's settings, Avalon Control (settings, in GTK 4), Neredy (a local
assistant and Russian tutor), HECTAS (packages from Guix and Nonguix) and Metamelayer
(packages from nixpkgs).")
    (license license:gpl3+)))
