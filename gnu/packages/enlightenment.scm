;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Tomáš Čech <sleep_walker@suse.cz>
;;; Copyright © 2015 Daniel Pimentel <d4n1@member.fsf.org>
;;; Copyright © 2015, 2016, 2017 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2017 ng0 <ng0@no-reply.pragmatique.xyz>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages enlightenment)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (gnu packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages check)
  #:use-module (gnu packages code)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages fribidi)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xorg))

(define-public efl
  (package
    (name "efl")
    (version "1.19.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://download.enlightenment.org/rel/libs/efl/efl-"
                    version ".tar.xz"))
              (sha256
               (base32
                "0fndwraca9rg0bz3al4isdprvyw56szr88qiyvglb4j8ygsylscc"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("compositeproto" ,compositeproto)
       ("curl" ,curl)
       ("ghostscript" ,ghostscript)
       ("giflib" ,giflib)
       ("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)
       ("libexif" ,libexif)
       ("libjpeg" ,libjpeg)
       ("libraw" ,libraw)
       ("librsvg" ,librsvg)
       ("libspectre" ,libspectre)
       ("libtiff" ,libtiff)
       ("libwebp" ,libwebp)
       ("libx11" ,libx11)
       ("libxau" ,libxau)
       ("libxcomposite" ,libxcomposite)
       ("libxcursor" ,libxcursor)
       ("libxdamage" ,libxdamage)
       ("libxdmcp" ,libxdmcp)
       ("libxext" ,libxext)
       ("libxi" ,libxi)
       ("libxfixes" ,libxfixes)
       ("libxinerama" ,libxinerama)
       ("libxp" ,libxp)
       ("libxrandr" ,libxrandr)
       ("libxrender" ,libxrender)
       ("libxscrnsaver" ,libxscrnsaver)
       ("libxtst" ,libxtst)
       ("lz4" ,lz4)
       ("mesa" ,mesa)
       ("openjpeg" ,openjpeg-1)
       ("poppler" ,poppler)
       ("printproto" ,printproto)
       ("scrnsaverproto" ,scrnsaverproto)
       ("xextproto" ,xextproto)
       ("xinput" ,xinput)
       ("xpr" ,xpr)
       ("xproto" ,xproto)))
    (propagated-inputs
     ;; All these inputs are in package config files in section
     ;; Requires.private.
     `(("bullet" ,bullet) ; ephysics.pc
       ("dbus" ,dbus) ; eldbus.pc, elementary.pc, elocation.pc, ethumb_client.pc
       ("eudev" ,eudev) ; eeze.pc
       ("fontconfig" ,fontconfig) ; evas.pc, evas-cxx.pc
       ("freetype" ,freetype) ; evas.pc, evas-cxx.pc
       ("fribidi" ,fribidi) ; evas.pc, evas-cxx.pc
       ("glib" ,glib) ; ecore.pc, ecore-cxx.pc
       ("harfbuzz" ,harfbuzz) ; evas.pc, evas-cxx.pc
       ("luajit" ,luajit) ; elua.pc, evas.pc, evas-cxx.pc
       ("libpng" ,libpng) ; evas.pc, evas-cxx.pc
       ("libsndfile" ,libsndfile) ; ecore-audio.pc, ecore-audio-cxx.pc
       ("openssl" ,openssl) ; ecore-con.pc, eet.pc, eet-cxx.pc, emile.pc
       ("pulseaudio" ,pulseaudio) ; ecore-audio.pc, ecore-audio-cxx.pc
       ("util-linux" ,util-linux) ; mount: eeze.pc
       ("zlib" ,zlib))) ; eet.pc, eet-cxx.pc, emile.pc
    (arguments
     `(#:configure-flags '("--disable-silent-rules"
                           "--disable-systemd"
                           "--enable-liblz4"
                           "--enable-xinput22"
                           "--enable-image-loader-webp"
                           "--enable-multisense"
                           "--with-opengl=es"
                           "--enable-egl"
                           "--enable-harfbuzz")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-home-directory
           ;; FATAL: Cannot create run dir '/homeless-shelter/.run' - errno=2
           (lambda _ (setenv "HOME" "/tmp") #t)))))
    (home-page "https://www.enlightenment.org/about-efl")
    (synopsis "Enlightenment Foundation Libraries")
    (description
     "Enlightenment Foundation Libraries is a set of libraries developed
for Enlightenment.  Libraries covers data serialization, wide support for
graphics rendering, UI layout and themes, interaction with OS, access to
removable devices or support for multimedia.")
    ;; Different parts are under different licenses.
    (license (list license:bsd-2 license:lgpl2.1 license:zlib))))

(define-public terminology
  (package
    (name "terminology")
    (version "1.0.0")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "https://download.enlightenment.org/rel/apps/"
                              "terminology/terminology-" version ".tar.xz"))
              (sha256
               (base32
                "1x4j2q4qqj10ckbka0zaq2r2zm66ff1x791kp8slv1ff7fw45vdz"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-home-directory
           ;; FATAL: Cannot create run dir '/homeless-shelter/.run' - errno=2
           (lambda _ (setenv "HOME" "/tmp") #t)))))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("efl" ,efl)))
    (home-page "https://www.enlightenment.org/about-terminology")
    (synopsis "Powerful terminal emulator based on EFL")
    (description
     "Terminology is fast and feature rich terminal emulator.  It is solely
based on Enlightenment Foundation Libraries.  It supports multiple tabs, UTF-8,
URL and local path detection, themes, popup based content viewer for non-text
contents and more.")
    (license license:bsd-2)))

(define-public rage
  (package
    (name "rage")
    (version "0.2.1")
    (source (origin
              (method url-fetch)
              (uri
               (string-append
                "https://download.enlightenment.org/rel/apps/rage/rage-"
                version ".tar.xz"))
              (sha256
               (base32
                "06kbgcnbhl9clhdl7k983m4d0n6ggsl4qvizzi1nrp8c7np87fix"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-home-directory
           ;; FATAL: Cannot create run dir '/homeless-shelter/.run' - errno=2
           (lambda _ (setenv "HOME" "/tmp") #t)))))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("efl" ,efl)))
    (home-page "https://www.enlightenment.org/about-rage")
    (synopsis "Video and audio player based on EFL")
    (description
     "Rage is a video and audio player written with Enlightenment Foundation
Libraries with some extra bells and whistles.")
    (license license:bsd-2)))

(define-public enlightenment
  (package
    (name "enlightenment")
    (version "0.21.8")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "https://download.enlightenment.org/rel/apps/"
                              name "/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "0cjjiip12hd8bfjl9ccl3vzl81pxh1wpymxk2yvrzf6ap5girhps"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags '("--enable-mount-eeze")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'set-system-actions
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((xkeyboard (assoc-ref inputs "xkeyboard-config"))
                   (utils     (assoc-ref inputs "util-linux")))
               ;; We need to patch the path to 'base.lst' to be able
               ;; to switch the keyboard layout in E.
               (substitute* "src/modules/xkbswitch/e_mod_parse.c"
                 (("/usr/share/X11/xkb/rules/xorg.lst")
                  (string-append xkeyboard
                                 "/share/X11/xkb/rules/base.lst")))
               (substitute* "configure"
                 (("/bin/mount") (string-append utils "/bin/mount"))
                 (("/bin/umount") (string-append utils "/bin/umount"))
                 (("/usr/bin/eject") (string-append utils "/bin/eject"))
                 ; TODO: Replace suspend and hibernate also.
                 (("/sbin/shutdown -h now") "/run/current-system/profile/sbin/halt")
                 (("/sbin/shutdown -r now") "/run/current-system/profile/sbin/reboot"))
               #t))))))
    (native-inputs
     `(("gettext" ,gettext-minimal)
       ("pkg-config" ,pkg-config)
       ("util-linux" ,util-linux)))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("dbus" ,dbus)
       ("efl" ,efl)
       ("freetype" ,freetype)
       ("libxcb" ,libxcb)
       ("libxext" ,libxext)
       ("linux-pam" ,linux-pam)
       ("xcb-util-keysyms" ,xcb-util-keysyms)
       ("xkeyboard-config" ,xkeyboard-config)))
    (home-page "https://www.enlightenment.org/about-enlightenment")
    (synopsis "Lightweight desktop environment")
    (description
     "Enlightenment is resource friendly desktop environment with integrated
file manager, wide range of configuration options, plugin system allowing to
unload unused functionality, with support for touchscreen and suitable for
embedded systems.")
    (license license:bsd-2)))

(define-public python-efl
  (package
    (name "python-efl")
    (version "1.19.0")
    (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "python-efl" version))
        (sha256
         (base32
          "0l0f9bv1134qh5376p5asycncidrhp8hdb6qwd8ybr1a61q9zq67"))))
    (build-system python-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
        (replace 'build
          (lambda _
            (zero?
              (system* "env" "ENABLE_CYTHON=1" "python" "setup.py" "build"))))
        (add-before 'build 'set-flags
         (lambda _
           (setenv "CFLAGS"
                   (string-append "-I" (assoc-ref %build-inputs "python-dbus")
                                  "/include/dbus-1.0"))
           #t))
        (add-before 'check 'set-environment
          (lambda _
            ;; Some tests require write access to HOME.
            (setenv "HOME" "/tmp")
            #t)))
       ;; FIXME: Some tests require a running D-Bus server or a network
       ;; connection and should be disabled. Other test failures looks
       ;; legitimate. Disabled for now, needs work!
       #:tests? #f))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("python-cython" ,python-cython)))
    (inputs
     `(("efl" ,efl)
       ("python-dbus" ,python-dbus)))
    (home-page "https://www.enlightenment.org/")
    (synopsis "Python bindings for EFL")
    (description
     "PYTHON-EFL are the python bindings for the whole Enlightenment Foundation
Libraries stack (eo, evas, ecore, edje, emotion, ethumb and elementary).")
    (license license:lgpl3)))

(define-public python2-efl
  (package-with-python2 python-efl))

(define-public edi
  (package
    (name "edi")
    (version "0.5.1")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/ajwillia-ms/edi/releases/"
                            "download/v" version "/edi-" version ".tar.bz2"))
        (sha256
         (base32
          "0k0ymi9ilhkypqb9pniv365kh3jgbl2g2k0ylvsmisn2jhbqk49a"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-home-directory
           ;; FATAL: Cannot create run dir '/homeless-shelter/.run' - errno=2
           (lambda _ (setenv "HOME" "/tmp") #t)))
       #:configure-flags '("--with-tests=coverage")))
    (native-inputs
     `(("check" ,check)
       ("lcov" ,lcov)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("clang" ,clang)
       ("efl" ,efl)))
    (home-page "https://www.enlightenment.org/about-edi")
    (synopsis "Development environment for Enlightenment")
    (description "EDI is a development environment designed for and built using
the EFL.  It's aim is to create a new, native development environment for Linux
that tries to lower the barrier to getting involved in Enlightenment development
and in creating applications based on the Enlightenment Foundation Library suite.")
    (license (list license:public-domain ; data/extra/skeleton
                   license:gpl2))))      ; edi

(define-public lekha
  (package
    (name "lekha")
    (version "0.2.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "Lekha" version))
              (sha256
               (base32
                "0zr6i74ik58pbzrd7r9l7sawqbdv0r2c1a9927qkqzwga27x8j15"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f ; no test target
       #:python ,python-2
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-data-location
           (lambda _ (substitute* "setup.py"
                       (("'/usr/")"'"))
             #t)))))
    (propagated-inputs
     `(("python2-efl" ,python2-efl)
       ("python2-pypdf2" ,python2-pypdf2)
       ("python2-pyxdg" ,python2-pyxdg)))
    (synopsis "Simple PDF viewer")
    (description
     "Simple PDF viewer based on the Enlightenment Foundation Libraries.")
    (home-page "https://github.com/kaihu/lekha")
    (license license:gpl3+)))
