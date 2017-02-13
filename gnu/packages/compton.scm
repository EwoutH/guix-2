;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 José Miguel Sánchez García <jmi2k@openmailbox.org>
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

(define-module (gnu packages compton)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))

(define-public compton
  (let ((upstream-version "0.1_beta2"))
    (package
      (name "compton")
      (version (string-filter (char-set-complement (char-set #\_))
                              upstream-version))
      (source (origin
                (method url-fetch)
                (uri (string-append
                      "https://github.com/chjj/" name "/archive/v"
                      upstream-version ".tar.gz"))
                (sha256
                 (base32
                  "02dhlqqcwnmlf2dxg7rd4lapgqahgndzixdkbpxicq9jawmdb73v"))
                (file-name (string-append name "-" version "-checkout"))))
      (build-system gnu-build-system)
      (inputs
       `(("dbus" ,dbus)
         ("docbook-xml" ,docbook-xml)
         ("libconfig" ,libconfig)
         ("libx11" ,libx11)
         ("libxcomposite" ,libxcomposite)
         ("libxdamage" ,libxdamage)
         ("libxext" ,libxext)
         ("libxfixes" ,libxfixes)
         ("libxinerama" ,libxinerama)
         ("libxml2" ,libxml2)
         ("libxrandr" ,libxrandr)
         ("libxrender" ,libxrender)
         ("libxslt" ,libxslt)
         ("mesa" ,mesa)
         ("xprop" ,xprop)
         ("xwininfo" ,xwininfo)))
      (native-inputs
       `(("asciidoc" ,asciidoc)
         ("libdrm" ,libdrm)
         ("pkg-config" ,pkg-config)
         ("python" ,python)
         ("xproto" ,xproto)))
      (arguments
       `(#:make-flags (list
                       "CC=gcc"
                       "NO_REGEX_PCRE=1"          ; pcre makes build fail
                       (string-append "PREFIX=" (assoc-ref %outputs "out")))
         #:tests? #f                              ; no tests
         #:phases
         (modify-phases %standard-phases
           (delete 'configure))))
      (home-page "https://github.com/chjj/compton")
      (synopsis "Compositor for X11")
      (description
       "Compton is a compositor for the Xorg display server and a for of
xcompmgr-dana, which implements some changes like:

@itemize
@item OpenGL backend (@command{--backend glx}), in addition to the old X Render
backend.
@item Inactive window transparency (@command{-i}) and dimming
(@command{--inactive-dim}).
@item Menu transparency (@command{-m}, thanks to Dana).
@item Shadows are now enabled for argb windows, e.g terminals with transparency
@item Removed serverside shadows (and simple compositing) to clean the code,
the only option that remains is clientside shadows.
@item Configuration files (see the man page for more details).
@item Colored shadows (@command{--shadow-[red/green/blue]}).
@item A new fade system.
@item VSync support (not always working).
@item Blur of background of transparent windows, window color inversion (bad in
performance).
@item Some more options...
@end itemize\n")
      (license license:expat))))
