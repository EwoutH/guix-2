;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2016, 2017 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2017 Marius Bakke <mbakke@fastmail.com>
;;; Copyright © 2017 Mark H Weaver <mhw@netris.org>
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

(define-module (gnu packages libidn)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages libunistring)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public libidn
  (package
   (name "libidn")
   (version "1.33")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/libidn/libidn-" version
                                ".tar.gz"))
            (sha256
             (base32
              "068fjg2arlppjqqpzd714n1lf6gxkpac9v5yyvp1qwmv6nvam9s4"))))
   (build-system gnu-build-system)
;; FIXME: No Java and C# libraries are currently built.
   (synopsis "Internationalized string processing library")
   (description
     "libidn is a library implementing of the Stringprep, Punycode and IDNA
specifications.  These are used to encode and decode internationalized domain
names according to the IDNA2003 specifications.  It includes native C, C# and
Java libraries.")
   ;; The C code is dual-licensed gpl2+ lgpl3+, the manual is fdl1.3+,
   ;; the command line tool is gpl3+.
   (license (list gpl2+ gpl3+ lgpl3+ fdl1.3+))
   (home-page "https://www.gnu.org/software/libidn/")))

(define-public libidn2
  (package
    (name "libidn2")
    (version "2.0.2")
    (replacement libidn2-2.0.4)
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnu/libidn/" name "-" version
                                  ".tar.lz"))
              (sha256
               (base32
                "0pqaj8d01aj4i110669fincqs10kgynyqcrmq2q7pss8v9dcd1jq"))))
    (native-inputs
     `(("lzip" ,lzip)))
    (inputs
     `(("libunistring" ,libunistring)))
    (build-system gnu-build-system)
    (synopsis "Internationalized domain name library for IDNA2008")
    (description "Libidn2 is an internationalized domain library implementing
the IDNA2008 specifications.   Libidn2 is believed to be a complete IDNA2008
implementation, but has yet to be as extensively used as the original Libidn
library.")
    (home-page "https://www.gnu.org/software/libidn/#libidn2")
    ;; The command-line tool 'idn2' is GPL3+, while the library is dual-licensed
    ;; GPL2+ or LGPL3+.
    (license (list gpl2+ gpl3+ lgpl3+))))

(define-public libidn2-2.0.4
  (package
    (inherit libidn2)
    (name "libidn2")
    (version "2.0.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnu/libidn/" name "-" version
                                  ".tar.lz"))
              (sha256
               (base32
                "00f2fyw5kwr9is3cdn5h9arzxp0lnvg0z9bb9zyfs0dq81gaqim4"))))))
