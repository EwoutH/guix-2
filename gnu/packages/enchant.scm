;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 Marek Benc <merkur32@gmail.com>
;;; Copyright © 2018 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages enchant)
  #:use-module (gnu packages)
  #:use-module (gnu packages aspell)
  #:use-module (gnu packages check)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages pkg-config)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses))

(define-public enchant
  (package
    (name "enchant")
    (version "2.2.3")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/AbiWord/enchant/"
                            "releases/download/v" version "/enchant-"
                            version ".tar.gz"))
        (sha256
         (base32
          "0v87p1ls0gym95qirijpclk650sjbkcjjl6ssk059zswcwaykn5b"))))
    (build-system gnu-build-system)
    ;; FIXME: Many of the tests fail for unknown reasons.
    (arguments '(#:tests? #f))
    (inputs
     `(("aspell" ,aspell) ;; Currently, the only supported backend in Guix
       ("glib" ,glib)))   ;; is aspell. (This information might be old)
    (native-inputs
     `(("glib:bin" ,glib "bin")
       ("unittest-cpp" ,unittest-cpp)
       ("pkg-config" ,pkg-config)))
    (synopsis "Multi-backend spell-checking library wrapper")
    (description
     "On the surface, Enchant appears to be a generic spell checking library.
Looking closer, you'll see the Enchant is more-or-less a fancy wrapper around
the @code{dlopen()} system call.

Enchant steps in to provide uniformity and conformity on top of these libraries,
and implement certain features that may be lacking in any individual provider
library.  Everything should \"just work\" for any and every definition of \"just
working\".")
    (home-page "http://www.abisource.com/projects/enchant")
    (license lgpl2.1+)))
