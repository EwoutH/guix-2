;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014, 2015, 2016 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2016 Roel Janssen <roel@gnu.org>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2016 Thomas Danckaert <post@thomasdanckaert.be>
;;; Copyright © 2016, 2017 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages tex)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module (guix git-download)
  #:use-module (guix svn-download)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gd)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages image)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages base)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages zip)
  #:autoload   (gnu packages texinfo) (texinfo)
  #:use-module (ice-9 ftw)
  #:use-module (srfi srfi-1))

(define texlive-extra-src
  (origin
    (method url-fetch)
    (uri "ftp://tug.org/historic/systems/texlive/2016/texlive-20160523-extra.tar.xz")
    (sha256 (base32
              "0q4a92zmwhn4ry6xgrp4k8wq11ax2sg9rg9yrsrdkr719y0x887a"))))

(define texlive-texmf-src
  (origin
    (method url-fetch)
    (uri "ftp://tug.org/historic/systems/texlive/2016/texlive-20160523b-texmf.tar.xz")
    (patches (search-patches "texlive-texmf-CVE-2016-10243.patch"))
    (patch-flags '("-p2"))
    (sha256 (base32
              "1dv8vgfzpczqw82hv9g7a8djhhyzywljmrarlcyy6g2qi5q51glr"))))

(define texlive-bin
  (package
   (name "texlive-bin")
   (version "2016")
   (source
    (origin
     (method url-fetch)
      (uri "ftp://tug.org/historic/systems/texlive/2016/texlive-20160523b-source.tar.xz")
      (sha256 (base32
               "1v91vahxlxkdra0qz3f132vvx5d9cx2jy84yl1hkch0agyj2rcx8"))))
   (build-system gnu-build-system)
   (inputs
    `(("texlive-extra-src" ,texlive-extra-src)
      ("cairo" ,cairo)
      ("fontconfig" ,fontconfig)
      ("fontforge" ,fontforge)
      ("freetype" ,freetype)
      ("gd" ,gd)
      ("gmp" ,gmp)
      ("ghostscript" ,ghostscript)
      ("graphite2" ,graphite2)
      ("harfbuzz" ,harfbuzz)
      ("icu4c" ,icu4c)
      ("libpaper" ,libpaper)
      ("libpng" ,libpng)
      ("libxaw" ,libxaw)
      ("libxt" ,libxt)
      ("mpfr" ,mpfr)
      ("perl" ,perl)
      ("pixman" ,pixman)
      ("poppler" ,poppler)
      ("potrace" ,potrace)
      ("python" ,python-2) ; incompatible with Python 3 (print syntax)
      ("ruby" ,ruby)
      ("tcsh" ,tcsh)
      ("teckit" ,teckit)
      ("zlib" ,zlib)
      ("zziplib" ,zziplib)))
   (native-inputs
    `(("pkg-config" ,pkg-config)))
   (arguments
    `(#:out-of-source? #t
      #:configure-flags
       `("--disable-native-texlive-build"
         "--with-system-cairo"
         "--with-system-freetype2"
         "--with-system-gd"
         "--with-system-gmp"
         "--with-system-graphite2"
         "--with-system-harfbuzz"
         "--with-system-icu"
         "--with-system-libgs"
         "--with-system-libpaper"
         "--with-system-libpng"
         "--with-system-mpfr"
         "--with-system-pixman"
         "--with-system-poppler"
         "--with-system-potrace"
         "--with-system-teckit"
         "--with-system-xpdf"
         "--with-system-zlib"
         "--with-system-zziplib")

      ;; Disable tests on mips64 to cope with a failure of luajiterr.test.
      ;; XXX FIXME fix luajit properly on mips64.
      #:tests? ,(not (string-prefix? "mips64" (or (%current-target-system)
                                                  (%current-system))))
      #:phases
       (modify-phases %standard-phases
         (add-after 'install 'postint
           (lambda* (#:key inputs outputs #:allow-other-keys #:rest args)
             (let* ((out (assoc-ref outputs "out"))
                    (share (string-append out "/share"))
                    (texlive-extra (assoc-ref inputs "texlive-extra-src"))
                    (unpack (assoc-ref %standard-phases 'unpack))
                    (patch-source-shebangs
                      (assoc-ref %standard-phases 'patch-source-shebangs)))
               ;; Create symbolic links for the latex variants and their
               ;; man pages.
               (with-directory-excursion (string-append out "/bin/")
                 (for-each symlink
                 '("pdftex" "pdftex"   "xetex"   "luatex")
                 '("latex"  "pdflatex" "xelatex" "lualatex")))
               (with-directory-excursion (string-append share "/man/man1/")
                 (symlink "luatex.1" "lualatex.1"))
               ;; Unpack texlive-extra and install tlpkg.
               (mkdir "texlive-extra")
               (with-directory-excursion "texlive-extra"
                 (apply unpack (list #:source texlive-extra))
                 (apply patch-source-shebangs (list #:source texlive-extra))
                 (system* "mv" "tlpkg" share))))))))
   (synopsis "TeX Live, a package of the TeX typesetting system")
   (description
    "TeX Live provides a comprehensive TeX document production system.
It includes all the major TeX-related programs, macro packages, and fonts
that are free software, including support for many languages around the
world.

This package contains the binaries.")
   (license (license:fsf-free "https://www.tug.org/texlive/copying.html"))
   (home-page "https://www.tug.org/texlive/")))

;; These variables specify the SVN tag and the matching SVN revision.
(define %texlive-tag "texlive-2017.0")
(define %texlive-revision 44445)

(define-public texlive-dvips
  (package
    (name "texlive-dvips")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/dvips"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "1k11yvz4q95bxyxczwvd4r177h6a2gg03xmf51kmgjgz8an2gq2w"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((target (string-append (assoc-ref %outputs "out")
                                      "/share/texmf-dist/dvips")))
           (mkdir-p target)
           (copy-recursively (assoc-ref %build-inputs "source") target)
           #t))))
    (home-page "http://www.ctan.org/pkg/dvips")
    (synopsis "DVI to PostScript drivers")
    (description "This package provides files needed for converting DVI files
to PostScript.")
    ;; Various free software licenses apply to individual files.
    (license (list license:lppl1.3c+
                   license:expat
                   license:lgpl3+))))

(define-public texlive-generic-unicode-data
  (package
    (name "texlive-generic-unicode-data")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/tex/generic/unicode-data"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "0ivrhp6jz31pl4z841g4ws41lmvdiwz4sslmhf02inlib79gz6r2"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((target (string-append (assoc-ref %outputs "out")
                                      "/share/texmf-dist/tex/generic/unicode-data")))
             (mkdir-p target)
             (copy-recursively (assoc-ref %build-inputs "source") target)
             #t))))
    (home-page "http://www.ctan.org/pkg/unicode-data")
    (synopsis "Unicode data and loaders for TeX")
    (description "This bundle provides generic access to Unicode Consortium
data for TeX use.  It contains a set of text files provided by the Unicode
Consortium which are currently all from Unicode 8.0.0, with the exception of
@code{MathClass.txt} which is not currently part of the Unicode Character
Database.  Accompanying these source data are generic TeX loader files
allowing this data to be used as part of TeX runs, in particular in building
format files.  Currently there are two loader files: one for general character
set up and one for initializing XeTeX character classes as has been carried
out to date by @code{unicode-letters.tex}. ")
    (license license:lppl1.3c+)))

(define-public texlive-generic-dehyph-exptl
  (package
    (name "texlive-generic-dehyph-exptl")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/tex/generic/dehyph-exptl"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "1l9wgv99qq0ysvlxqpj4g8bl0dywbzra4g8m2kmpg2fb0i0hczap"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((target (string-append (assoc-ref %outputs "out")
                                      "/share/texmf-dist/tex/generic/dehyph-exptl")))
           (mkdir-p target)
           (copy-recursively (assoc-ref %build-inputs "source") target)
           #t))))
    (home-page "http://projekte.dante.de/Trennmuster/WebHome")
    (synopsis "Hyphenation patterns for German")
    (description "The package provides experimental hyphenation patterns for
the German language, covering both traditional and reformed orthography.  The
patterns can be used with packages Babel and hyphsubst from the Oberdiek
bundle.")
    ;; Hyphenation patterns are under the Expat license; documentation is
    ;; under LPPL.
    (license (list license:expat license:lppl))))

(define-public texlive-generic-tex-ini-files
  (package
    (name "texlive-generic-tex-ini-files")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/tex/generic/tex-ini-files"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "1wh42n1lmzcvi3g6mm31nm3yd5ha5bl260xqc444jg1m9fdp3wz5"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((target (string-append (assoc-ref %outputs "out")
                                      "/share/texmf-dist/tex/generic/tex-ini-files")))
           (mkdir-p target)
           (copy-recursively (assoc-ref %build-inputs "source") target)
           #t))))
    (home-page "http://ctan.org/pkg/tex-ini-files")
    (synopsis "Files for creating TeX formats")
    (description "This bundle provides a collection of model \".ini\" files
for creating TeX formats.  These files are commonly used to introduced
distribution-dependent variations in formats.  They are also used to
allow existing format source files to be used with newer engines, for example
to adapt the plain e-TeX source file to work with XeTeX and LuaTeX.")
    (license license:public-domain)))

(define-public texlive-generic-hyph-utf8
  (package
    (name "texlive-generic-hyph-utf8")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/tex/generic/hyph-utf8"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "0ghizcz7ps16dzfqf66wwg5i181assc6qsm0g7g5dbmp909931vi"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((target (string-append (assoc-ref %outputs "out")
                                      "/share/texmf-dist/tex/generic/hyph-utf8")))
           (mkdir-p target)
           (copy-recursively (assoc-ref %build-inputs "source") target)
           #t))))
    (home-page "http://ctan.org/pkg/hyph-utf8")
    (synopsis "Hyphenation patterns expressed in UTF-8")
    (description "Modern native UTF-8 engines such as XeTeX and LuaTeX need
hyphenation patterns in UTF-8 format, whereas older systems require
hyphenation patterns in the 8-bit encoding of the font in use (such encodings
are codified in the LaTeX scheme with names like OT1, T2A, TS1, OML, LY1,
etc).  The present package offers a collection of conversions of existing
patterns to UTF-8 format, together with converters for use with 8-bit fonts in
older systems.  Since hyphenation patterns for Knuthian-style TeX systems are
only read at iniTeX time, it is hoped that the UTF-8 patterns, with their
converters, will completely supplant the older patterns.")
    ;; Individual files each have their own license.  Most of these files are
    ;; independent hyphenation patterns.
    (license (list license:lppl1.0+
                   license:lppl1.2+
                   license:lppl1.3
                   license:lppl1.3+
                   license:lppl1.3a+
                   license:lgpl2.1
                   license:lgpl2.1+
                   license:lgpl3+
                   license:gpl2+
                   license:gpl3+
                   license:mpl1.1
                   license:asl2.0
                   license:expat
                   license:bsd-3
                   license:cc0
                   license:public-domain
                   license:wtfpl2))))

(define-public texlive-metafont-base
  (package
    (name "texlive-metafont-base")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/metafont"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "1yl4n8cn5xqk2nc22zgzq6ymd7bhm6xx1mz3azip7i3ki4bhb5q5"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; no test target
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((cwd (getcwd)))
               (setenv "MFINPUTS"
                       (string-append cwd "/base:"
                                      cwd "/misc:"
                                      cwd "/roex:"
                                      cwd "/feynmf:"
                                      cwd "/mfpic:"
                                      cwd "/config")))
             (mkdir "build")
             (with-directory-excursion "build"
               (zero? (system* "inimf" "mf.mf")))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out  (assoc-ref outputs "out"))
                    (base (string-append out "/share/texmf-dist/web2c"))
                    (mf   (string-append out "/share/texmf-dist/metafont/base")))
               (mkdir-p base)
               (mkdir-p mf)
               (install-file "build/mf.base" base)
               (copy-recursively "base" mf)
               #t))))))
    (native-inputs
     `(("texlive-bin" ,texlive-bin)))
    (home-page "http://www.ctan.org/pkg/metafont")
    (synopsis "Metafont base files")
    (description "This package provides the Metafont base files needed to
build fonts using the Metafont system.")
    (license license:knuth)))

(define-public texlive-fonts-cm
  (package
    (name "texlive-fonts-cm")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/fonts/source/public/cm"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "045k5b9rdmbxpy1a3006l1x96z1rd18vg3cwrvnld9bqybw5qz44"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-26))
       #:tests? #f ; no tests
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((mf (assoc-ref inputs "texlive-metafont-base")))
               ;; Tell mf where to find mf.base
               (setenv "MFBASES" (string-append mf "/share/texmf-dist/web2c"))
               ;; Tell mf where to look for source files
               (setenv "MFINPUTS"
                       (string-append (getcwd) ":"
                                      mf "/share/texmf-dist/metafont/base")))
             (mkdir "build")
             (every (lambda (font)
                      (format #t "building font ~a\n" font)
                      (zero? (system* "mf" "-progname=mf"
                                      "-output-directory=build"
                                      (string-append "\\"
                                                     "mode:=ljfour; "
                                                     "mag:=1; "
                                                     "batchmode; "
                                                     "input "
                                                     (basename font ".mf")))))
                    (find-files "." "cm(.*[0-9]+.*|inch)\\.mf$"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (tfm (string-append
                          out "/share/texmf-dist/fonts/tfm/public/cm"))
                    (mf  (string-append
                          out "/share/texmf-dist/fonts/source/public/cm")))
               (for-each (cut install-file <> tfm)
                         (find-files "build" "\\.*"))
               (for-each (cut install-file <> mf)
                         (find-files "." "\\.mf"))
               #t))))))
    (native-inputs
     `(("texlive-bin" ,texlive-bin)
       ("texlive-metafont-base" ,texlive-metafont-base)))
    (home-page "http://www.ctan.org/pkg/cm")
    (synopsis "Computer Modern fonts for TeX")
    (description "This package provides the Computer Modern fonts by Donald
Knuth.  The Computer Modern font family is a large collection of text,
display, and mathematical fonts in a range of styles, based on Monotype Modern
8A.")
    (license license:knuth)))

(define-public texlive-fonts-knuth-lib
  (package
    (name "texlive-fonts-knuth-lib")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/fonts/source/public/knuth-lib"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "0in9aqyi8jkyf9d16z0li50z5fpwj1iwgwm83gmvwqcf7chfs04y"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-26))
       #:tests? #f ; no tests
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((mf (assoc-ref inputs "texlive-metafont-base")))
               ;; Tell mf where to find mf.base
               (setenv "MFBASES"
                       (string-append mf "/share/texmf-dist/web2c"))
               ;; Tell mf where to look for source files
               (setenv "MFINPUTS"
                       (string-append (getcwd) ":"
                                      mf "/share/texmf-dist/metafont/base")))
             (mkdir "build")
             (zero? (system* "mf" "-progname=mf"
                             "-output-directory=build"
                             (string-append "\\"
                                            "mode:=ljfour; "
                                            "mag:=1; "
                                            "batchmode; "
                                            "input manfnt")))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (tfm (string-append
                          out "/share/texmf-dist/fonts/tfm/public/knuth-lib"))
                    (mf  (string-append
                          out "/share/texmf-dist/fonts/source/public/knuth-lib")))
               (for-each (cut install-file <> tfm)
                         (find-files "build" "\\.*"))
               (for-each (cut install-file <> mf)
                         (find-files "." "\\.mf"))
               #t))))))
    (native-inputs
     `(("texlive-bin" ,texlive-bin)
       ("texlive-metafont-base" ,texlive-metafont-base)))
    (home-page "https://www.ctan.org/pkg/knuth-lib")
    (synopsis "Small library of METAFONT sources")
    (description "This is a collection of core TeX and METAFONT macro files
from Donald Knuth, including the plain format, plain base, and the MF logo
fonts.")
    (license license:knuth)))

(define-public texlive-fonts-latex
  (package
    (name "texlive-fonts-latex")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/fonts/source/public/latex-fonts"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "0ypsm4xv9cw0jckk2qc7gi9hcmhf31mrg56pz3llyx3yd9vq2lps"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-26))
       #:tests? #f                      ; no tests
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((mf (assoc-ref inputs "texlive-metafont-base")))
               ;; Tell mf where to find mf.base
               (setenv "MFBASES" (string-append mf "/share/texmf-dist/web2c"))
               ;; Tell mf where to look for source files
               (setenv "MFINPUTS"
                       (string-append (getcwd) ":"
                                      mf "/share/texmf-dist/metafont/base:"
                                      (assoc-ref inputs "texlive-fonts-cm")
                                      "/share/texmf-dist/fonts/source/public/cm")))
             (mkdir "build")
             (every (lambda (font)
                      (format #t "building font ~a\n" font)
                      (zero? (system* "mf" "-progname=mf"
                                      "-output-directory=build"
                                      (string-append "\\"
                                                     "mode:=ljfour; "
                                                     "mag:=1; "
                                                     "batchmode; "
                                                     "input " font))))
                    '("icmcsc10" "icmex10" "icmmi8" "icmsy8" "icmtt8"
                      "ilasy8" "ilcmss8" "ilcmssb8" "ilcmssi8"
                      "lasy5" "lasy6" "lasy7" "lasy8" "lasy9" "lasy10" "lasyb10"
                      "lcircle10" "lcirclew10" "lcmss8" "lcmssb8" "lcmssi8"
                      "line10" "linew10"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (tfm (string-append
                          out "/share/texmf-dist/fonts/tfm/public/latex-fonts"))
                    (mf  (string-append
                          out "/share/texmf-dist/fonts/source/public/latex-fonts")))
               (for-each (cut install-file <> tfm)
                         (find-files "build" "\\.*"))
               (for-each (cut install-file <> mf)
                         (find-files "." "\\.mf"))
               #t))))))
    (native-inputs
     `(("texlive-bin" ,texlive-bin)
       ("texlive-metafont-base" ,texlive-metafont-base)
       ("texlive-fonts-cm" ,texlive-fonts-cm)))
    (home-page "http://www.ctan.org/pkg/latex-fonts")
    (synopsis "Collection of fonts used in LaTeX distributions")
    (description "This is a collection of fonts for use with standard LaTeX
packages and classes. It includes invisible fonts (for use with the slides
class), line and circle fonts (for use in the picture environment) and LaTeX
symbol fonts.")
    (license license:lppl1.2+)))

;; This provides etex.src which is needed to build various formats, including
;; luatex.fmt and pdflatex.fmt
(define-public texlive-tex-plain
  (package
    (name "texlive-tex-plain")
    (version (number->string %texlive-revision))
    (source (origin
              (method svn-fetch)
              (uri (svn-reference
                    (url (string-append "svn://www.tug.org/texlive/tags/"
                                        %texlive-tag "/Master/texmf-dist/"
                                        "/tex/plain"))
                    (revision %texlive-revision)))
              (sha256
               (base32
                "1ifmbyl3ir8k0v1g25xjb5rcyy5vhj8a3fa2088nczga09hna5vn"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((target (string-append (assoc-ref %outputs "out")
                                      "/share/texmf-dist/tex/plain")))
           (mkdir-p target)
           (copy-recursively (assoc-ref %build-inputs "source") target)
           #t))))
    (home-page "https://www.ctan.org/pkg/plain")
    (synopsis "Plain TeX format and supporting files")
    (description
     "Contains files used to build the Plain TeX format, as described in the
TeXbook, together with various supporting files (some also discussed in the
book).")
    (license license:knuth)))

(define (texlive-ref component id)
  "Return a <svn-reference> object for the package ID, which is part of the
given Texlive COMPONENT."
  (svn-reference
   (url (string-append "svn://www.tug.org/texlive/tags/"
                       %texlive-tag "/Master/texmf-dist/"
                       "source/" component "/" id))
   (revision %texlive-revision)))

(define-public texlive-latex-base
  (let ((texlive-dir
         (lambda (dir hash)
           (origin
             (method svn-fetch)
             (uri (svn-reference
                   (url (string-append "svn://www.tug.org/texlive/tags/"
                                       %texlive-tag "/Master/texmf-dist/"
                                       dir))
                   (revision %texlive-revision)))
             (sha256 (base32 hash))))))
    (package
      (name "texlive-latex-base")
      (version (number->string %texlive-revision))
      (source (origin
                (method svn-fetch)
                (uri (texlive-ref "latex" "base"))
                (sha256
                 (base32
                  "1h9pir2hz6i9avc4lrl733p3zf4rpkg8537x1zdbhs91hvhikw9k"))))
      (build-system gnu-build-system)
      (arguments
       `(#:modules ((guix build gnu-build-system)
                    (guix build utils)
                    (ice-9 match)
                    (srfi srfi-1)
                    (srfi srfi-26))
         #:tests? #f                    ; no tests
         #:phases
         (modify-phases %standard-phases
           (delete 'configure)
           (replace 'build
             (lambda* (#:key inputs #:allow-other-keys)
               ;; Find required fonts
               (setenv "TFMFONTS"
                       (string-append (assoc-ref inputs "texlive-fonts-cm")
                                      "/share/texmf-dist/fonts/tfm/public/cm:"
                                      (assoc-ref inputs "texlive-fonts-latex")
                                      "/share/texmf-dist/fonts/tfm/public/latex-fonts:"
                                      (assoc-ref inputs "texlive-fonts-knuth-lib")
                                      "/share/texmf-dist/fonts/tfm/public/knuth-lib"))
               (setenv "TEXINPUTS"
                       (string-append
                        (getcwd) ":"
                        (getcwd) "/build:"
                        (string-join
                         (append-map (match-lambda
                                       ((_ . dir)
                                        (find-files dir
                                                    (lambda (_ stat)
                                                      (eq? 'directory (stat:type stat)))
                                                    #:directories? #t
                                                    #:stat stat)))
                                     inputs)
                         ":")))

               ;; Create an empty texsys.cfg, because latex.ltx wants to include
               ;; it.  This file must exist and it's fine if it's empty.
               (with-output-to-file "texsys.cfg"
                 (lambda _ (format #t "%")))

               (mkdir "build")
               (mkdir "web2c")
               (and (zero? (system* "luatex" "-ini" "-interaction=batchmode"
                                    "-output-directory=build"
                                    "unpack.ins"))
                    ;; LaTeX and XeTeX require e-TeX, which is enabled only in
                    ;; extended mode (activated with a leading asterisk).  We
                    ;; should not use luatex here, because that would make the
                    ;; generated format files incompatible with any other TeX
                    ;; engine.

                    ;; FIXME: XeTeX fails to build because neither
                    ;; \XeTeXuseglyphmetrics nor \XeTeXdashbreakstate are
                    ;; defined.
                    (every
                     (lambda (format)
                       (zero? (system* "latex" "-ini" "-interaction=batchmode"
                                       "-output-directory=web2c"
                                       "-translate-file=cp227.tcx"
                                       (string-append "*" format ".ini"))))
                     '("latex" ;"xetex"
                       ))
                    (every
                     (lambda (format)
                       (zero? (system* "luatex" "-ini" "-interaction=batchmode"
                                       "-output-directory=web2c"
                                       (string-append format ".ini"))))
                     '("dviluatex" "dvilualatex" "luatex" "lualatex" "xelatex")))))
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (target (string-append
                               out "/share/texmf-dist/tex/latex/base"))
                      (web2c (string-append
                              out "/share/texmf-dist/web2c")))
                 (mkdir-p target)
                 (mkdir-p web2c)
                 (for-each delete-file (find-files "." "\\.(log|aux)$"))
                 (for-each (cut install-file <> target)
                           (find-files "build" ".*"))
                 (for-each (cut install-file <> web2c)
                           (find-files "web2c" ".*"))
                 #t))))))
      (native-inputs
       `(("texlive-bin" ,texlive-bin)
         ("texlive-generic-unicode-data" ,texlive-generic-unicode-data)
         ("texlive-generic-dehyph-exptl" ,texlive-generic-dehyph-exptl)
         ("texlive-generic-tex-ini-files" ,texlive-generic-tex-ini-files)
         ("texlive-latex-latexconfig"
          ,(texlive-dir "tex/latex/latexconfig/"
                        "1zb3j49cj8p75yph6c8iysjp7qbdvghwf0mn9j0l7qq3qkbz2xaf"))
         ("texlive-generic-hyph-utf8" ,texlive-generic-hyph-utf8)
         ("texlive-generic-hyphen"
          ,(texlive-dir "tex/generic/hyphen/"
                        "0xim36wybw2625yd0zwlp9m2c2xrcybw58gl4rih9nkph0wqwwhd"))
         ("texlive-generic-ruhyphen"
          ,(texlive-dir "tex/generic/ruhyphen/"
                        "14rjkpl4zkjqs13rcf9kcd24mn2kx7i1jbdwxq8ds94bi66ylzsd"))
         ("texlive-generic-ukrhyph"
          ,(texlive-dir "tex/generic/ukrhyph/"
                        "1cfwdg2rhbayl3w0x1xqd36d45zbc96f029myp13s7cb6kbmbppv"))
         ("texlive-generic-config"
          ,(texlive-dir "tex/generic/config/"
                        "19vj088p4kkp6xll0141m4kl6ssgdzhs3g10i232khb07aqiag8s"))
         ("texlive-tex-plain" ,texlive-tex-plain)
         ("texlive-fonts-cm" ,texlive-fonts-cm)
         ("texlive-fonts-latex" ,texlive-fonts-latex)
         ("texlive-fonts-knuth-lib" ,texlive-fonts-knuth-lib)))
      (home-page "http://www.ctan.org/pkg/latex-base")
      (synopsis "Base sources of LaTeX")
      (description
       "This bundle comprises the source of LaTeX itself, together with several
packages which are considered \"part of the kernel\".  This bundle, together
with the required packages, constitutes what every LaTeX distribution should
contain.")
      (license license:lppl1.3c+))))

(define texlive-texmf
  (package
   (name "texlive-texmf")
   (version "2016")
   (source texlive-texmf-src)
   (build-system gnu-build-system)
   (inputs
    `(("texlive-bin" ,texlive-bin)
      ("lua" ,lua)
      ("perl" ,perl)
      ("python" ,python-2) ; incompatible with Python 3 (print syntax)
      ("ruby" ,ruby)
      ("tcsh" ,tcsh)))
   (arguments
    `(#:modules ((guix build gnu-build-system)
                 (guix build utils)
                 (srfi srfi-26))

      ;; This package takes 4 GiB, which we can't afford to distribute from
      ;; our servers.
      #:substitutable? #f

      #:phases
        (modify-phases (map (cut assq <> %standard-phases)
                            '(set-paths unpack patch-source-shebangs))
          (add-after 'patch-source-shebangs 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((share (string-append (assoc-ref outputs "out") "/share")))
                (mkdir-p share)
                (system* "mv" "texmf-dist" share))))
          (add-after 'install 'texmf-config
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (share (string-append out "/share"))
                     (texmfroot (string-append share "/texmf-dist/web2c"))
                     (texmfcnf (string-append texmfroot "/texmf.cnf"))
                     (texlive-bin (assoc-ref inputs "texlive-bin"))
                     (texbin (string-append texlive-bin "/bin"))
                     (tlpkg (string-append texlive-bin "/share/tlpkg")))
                ;; Register SHARE as TEXMFROOT in texmf.cnf.
                (substitute* texmfcnf
                  (("TEXMFROOT = \\$SELFAUTOPARENT")
                   (string-append "TEXMFROOT = " share))
                  (("TEXMFLOCAL = \\$SELFAUTOGRANDPARENT/texmf-local")
                   "TEXMFLOCAL = $SELFAUTODIR/share/texmf-local")
                  (("!!\\$TEXMFLOCAL") "$TEXMFLOCAL"))
                ;; Register paths in texmfcnf.lua, needed for context.
                (substitute* (string-append texmfroot "/texmfcnf.lua")
                  (("selfautodir:") out)
                  (("selfautoparent:") (string-append share "/")))
                ;; Set path to TeXLive Perl modules
                (setenv "PERL5LIB"
                        (string-append (getenv "PERL5LIB") ":" tlpkg))
                ;; Configure the texmf-dist tree; inspired from
                ;; http://slackbuilds.org/repository/13.37/office/texlive/
                (setenv "PATH" (string-append (getenv "PATH") ":" texbin))
                (setenv "TEXMFCNF" texmfroot)
                (system* "updmap-sys" "--nohash" "--syncwithtrees")
                (system* "mktexlsr")
                (system* "fmtutil-sys" "--all")))))))
   (properties `((max-silent-time . 9600))) ; don't time out while grafting
   (synopsis "TeX Live, a package of the TeX typesetting system")
   (description
    "TeX Live provides a comprehensive TeX document production system.
It includes all the major TeX-related programs, macro packages, and fonts
that are free software, including support for many languages around the
world.

This package contains the complete tree of texmf-dist data.")
   (license (license:fsf-free "https://www.tug.org/texlive/copying.html"))
   (home-page "https://www.tug.org/texlive/")))

(define-public texlive
  (package
   (name "texlive")
   (version "2016")
   (source #f)
   (build-system trivial-build-system)
   (inputs `(("bash" ,bash) ; for wrap-program
             ("texlive-bin" ,texlive-bin)
             ("texlive-texmf" ,texlive-texmf)))
   (native-search-paths
    (list (search-path-specification
           (variable "TEXMFLOCAL")
           (files '("share/texmf-local")))))
   (arguments
    `(#:modules ((guix build utils))
      #:builder
        ;; Build the union of texlive-bin and texlive-texmf, but take the
        ;; conflicting subdirectory share/texmf-dist from texlive-texmf.
        (begin
          (use-modules (guix build utils))
          (let ((out (assoc-ref %outputs "out"))
                (bin (assoc-ref %build-inputs "texlive-bin"))
                (texmf (assoc-ref %build-inputs "texlive-texmf"))
                (bash (assoc-ref %build-inputs "bash")))
               (mkdir out)
               (with-directory-excursion out
                 (for-each
                   (lambda (name)
                     (symlink (string-append bin "/" name) name))
                   '("include" "lib"))
                 (mkdir "bin")
                 (with-directory-excursion "bin"
                   (setenv "PATH" (string-append bash "/bin"))
                   (for-each
                     (lambda (name)
                       (symlink name (basename name))
                       (wrap-program
                         (basename name)
                         `("TEXMFCNF" =
                           (,(string-append texmf "/share/texmf-dist/web2c")))))
                     (find-files (string-append bin "/bin/") "")))
                 (mkdir "share")
                 (with-directory-excursion "share"
                   (for-each
                     (lambda (name)
                       (symlink (string-append bin "/share/" name) name))
                     '("info" "man" "tlpkg"))
                   (for-each
                     (lambda (name)
                       (symlink (string-append texmf "/share/" name) name))
                     '("texmf-dist" "texmf-var"))))))))
   (synopsis "TeX Live, a package of the TeX typesetting system")
   (description
    "TeX Live provides a comprehensive TeX document production system.
It includes all the major TeX-related programs, macro packages, and fonts
that are free software, including support for many languages around the
world.

This package contains the complete TeX Live distribution.")
   (license (license:fsf-free "https://www.tug.org/texlive/copying.html"))
   (home-page "https://www.tug.org/texlive/")))


;; texlive-texmf-minimal is a pruned, small version of the texlive tree,
;; in particular dropping documentation and fonts.  It weighs in at 470 MiB
;; instead of 4 GiB.
(define texlive-texmf-minimal
  (package (inherit texlive-texmf)
   (name "texlive-texmf-minimal")
   (arguments
    (substitute-keyword-arguments
     (package-arguments texlive-texmf)
     ((#:modules modules)
      `((ice-9 ftw)
        (srfi srfi-1)
        ,@modules))
     ((#:phases phases)
      `(modify-phases ,phases
         (add-after 'unpack 'prune
           (lambda _
             (define (delete subdir exclude)
               "Delete all files and directories in SUBDIR except for those
given in the list EXCLUDE."
               (with-directory-excursion subdir
                 (for-each delete-file-recursively
                           (lset-difference equal?
                                            (scandir ".")
                                            (append '("." "..")
                                                    exclude)))))
             (with-directory-excursion "texmf-dist"
               (for-each delete-file-recursively
                         '("doc" "source" "tex4ht"))
               ;; Delete all subdirectories of "fonts", except for "tfm" and
               ;; any directories named "cm".
               (delete "fonts" '("afm" "map" "pk" "source" "tfm" "type1"))
               (delete "fonts/afm" '("public"))
               (delete "fonts/afm/public" '("amsfonts"))
               (delete "fonts/afm/public/amsfonts" '("cm"))
               (delete "fonts/map" '("dvips"))
               (delete "fonts/map/dvips" '("cm"))
               (delete "fonts/source" '("public"))
               (delete "fonts/source/public" '("cm"))
               (delete "fonts/tfm" '("public"))
               (delete "fonts/type1" '("public"))
               (delete "fonts/type1/public" '("amsfonts"))
               (delete "fonts/type1/public/amsfonts" '("cm")))
             #t))))))
   (description
    "TeX Live provides a comprehensive TeX document production system.
It includes all the major TeX-related programs, macro packages, and fonts
that are free software, including support for many languages around the
world.

This package contains a small subset of the texmf-dist data.")))


;; texlive-minimal is the same as texlive, but using texlive-texmf-minimal
;; instead of the full texlive-texmf. It can be used, for instance, as a
;; native input to packages that need texlive to build their documentation.
(define-public texlive-minimal
  (package (inherit texlive)
   (name "texlive-minimal")
   (inputs
    `(("texlive-texmf" ,texlive-texmf-minimal)
      ,@(alist-delete "texlive-texmf" (package-inputs texlive))))
   (native-search-paths
    (list (search-path-specification
           (variable "TEXMFLOCAL")
           (files '("share/texmf-local")))))
   (description
    "TeX Live provides a comprehensive TeX document production system.
It includes all the major TeX-related programs, macro packages, and fonts
that are free software, including support for many languages around the
world.

This package contains a small working part of the TeX Live distribution.")))

(define-public perl-text-bibtex
  (package
    (name "perl-text-bibtex")
    (version "0.77")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/A/AM/AMBS/Text-BibTeX-"
                           version ".tar.gz"))
       (sha256
        (base32
         "0kkfx8skk763pivz6h2ffy2zdp1lvy6d5sz0kjaj0mdbjffvnnb4"))))
    (build-system perl-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'add-output-directory-to-rpath
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "inc/MyBuilder.pm"
               (("-Lbtparse" line)
                (string-append "-Wl,-rpath="
                               (assoc-ref outputs "out") "/lib " line)))
             #t))
         (add-after 'unpack 'install-libraries-to-/lib
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "Build.PL"
               (("lib64") "lib"))
             #t)))))
    (native-inputs
     `(("perl-capture-tiny" ,perl-capture-tiny)
       ("perl-config-autoconf" ,perl-config-autoconf)
       ("perl-extutils-libbuilder" ,perl-extutils-libbuilder)
       ("perl-module-build" ,perl-module-build)))
    (home-page "http://search.cpan.org/dist/Text-BibTeX")
    (synopsis "Interface to read and parse BibTeX files")
    (description "@code{Text::BibTeX} is a Perl library for reading, parsing,
and processing BibTeX files.  @code{Text::BibTeX} gives you access to the data
at many different levels: you may work with BibTeX entries as simple field to
string mappings, or get at the original form of the data as a list of simple
values (strings, macros, or numbers) pasted together.")
    (license license:perl-license)))

(define-public biber
  (package
    (name "biber-next")
    (version "2.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/plk/biber/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "158smzgjhjvyabdv97si5q88zjj5l8j1zbfnddvzy6fkpfhskgkp"))))
    (build-system perl-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'install 'wrap-programs
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (perl5lib (getenv "PERL5LIB")))
               (wrap-program (string-append out "/bin/biber")
                 `("PERL5LIB" ":" prefix
                   (,(string-append perl5lib ":" out
                                    "/lib/perl5/site_perl")))))
             #t)))))
    (inputs
     `(("perl-autovivification" ,perl-autovivification)
       ("perl-class-accessor" ,perl-class-accessor)
       ("perl-data-dump" ,perl-data-dump)
       ("perl-data-compare" ,perl-data-compare)
       ("perl-data-uniqid" ,perl-data-uniqid)
       ("perl-datetime-format-builder" ,perl-datetime-format-builder)
       ("perl-datetime-calendar-julian" ,perl-datetime-calendar-julian)
       ("perl-file-slurp" ,perl-file-slurp)
       ("perl-ipc-cmd" ,perl-ipc-cmd)
       ("perl-ipc-run3" ,perl-ipc-run3)
       ("perl-list-allutils" ,perl-list-allutils)
       ("perl-list-moreutils" ,perl-list-moreutils)
       ("perl-mozilla-ca" ,perl-mozilla-ca)
       ("perl-regexp-common" ,perl-regexp-common)
       ("perl-log-log4perl" ,perl-log-log4perl)
       ;; We cannot use perl-unicode-collate here, because otherwise the
       ;; hardcoded hashes in the tests would differ.  See
       ;; https://mail-archive.com/debian-bugs-dist@lists.debian.org/msg1469249.html
       ;;("perl-unicode-collate" ,perl-unicode-collate)
       ("perl-unicode-normalize" ,perl-unicode-normalize)
       ("perl-unicode-linebreak" ,perl-unicode-linebreak)
       ("perl-encode-eucjpascii" ,perl-encode-eucjpascii)
       ("perl-encode-jis2k" ,perl-encode-jis2k)
       ("perl-encode-hanextra" ,perl-encode-hanextra)
       ("perl-xml-libxml" ,perl-xml-libxml)
       ("perl-xml-libxml-simple" ,perl-xml-libxml-simple)
       ("perl-xml-libxslt" ,perl-xml-libxslt)
       ("perl-xml-writer" ,perl-xml-writer)
       ("perl-sort-key" ,perl-sort-key)
       ("perl-text-csv" ,perl-text-csv)
       ("perl-text-csv-xs" ,perl-text-csv-xs)
       ("perl-text-roman" ,perl-text-roman)
       ("perl-uri" ,perl-uri)
       ("perl-text-bibtex" ,perl-text-bibtex)
       ("perl-libwww" ,perl-libwww)
       ("perl-lwp-protocol-https" ,perl-lwp-protocol-https)
       ("perl-business-isbn" ,perl-business-isbn)
       ("perl-business-issn" ,perl-business-issn)
       ("perl-business-ismn" ,perl-business-ismn)
       ("perl-lingua-translit" ,perl-lingua-translit)))
    (native-inputs
     `(("perl-config-autoconf" ,perl-config-autoconf)
       ("perl-extutils-libbuilder" ,perl-extutils-libbuilder)
       ("perl-module-build" ,perl-module-build)
       ;; for tests
       ("perl-file-which" ,perl-file-which)
       ("perl-test-more" ,perl-test-most) ; FIXME: "more" would be sufficient
       ("perl-test-differences" ,perl-test-differences)))
    (home-page "http://biblatex-biber.sourceforge.net/")
    (synopsis "Backend for the BibLaTeX citation management tool")
    (description "Biber is a BibTeX replacement for users of biblatex.  Among
other things it comes with full Unicode support.")
    (license license:artistic2.0)))

;; Our version of texlive comes with biblatex 3.4, which is only compatible
;; with biber 2.5 according to the compatibility matrix in the biber
;; documentation.
(define-public biber-2.5
  (package (inherit biber)
    (name "biber")
    (version "2.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/plk/biber/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "163sd343wkrzwnvj2003m2j0kz517jmjr4savw6f8bjxhj8fdrqv"))))
    (arguments
     (substitute-keyword-arguments (package-arguments biber)
       ((#:phases phases)
        `(modify-phases ,phases
           (add-before 'check 'delete-failing-test
             (lambda _
               (delete-file "t/sort-order.t")
               #t))))))
    (inputs
     `(("perl-date-simple" ,perl-date-simple)
       ,@(package-inputs biber)))))

(define-public rubber
  (package
    (name "rubber")
    (version "1.1")
    (source (origin
             (method url-fetch)
             (uri (list (string-append "https://launchpad.net/rubber/trunk/"
                                       version "/+download/rubber-"
                                       version ".tar.gz")
                        (string-append "http://ebeffara.free.fr/pub/rubber-"
                                       version ".tar.gz")))
             (sha256
              (base32
               "1xbkv8ll889933gyi2a5hj7hhh216k04gn8fwz5lfv5iz8s34gbq"))))
    (build-system gnu-build-system)
    (arguments '(#:tests? #f))                    ; no `check' target
    (inputs `(("texinfo" ,texinfo)
              ("python" ,python-2) ; incompatible with Python 3 (print syntax)
              ("which" ,which)))
    (home-page "https://launchpad.net/rubber")
    (synopsis "Wrapper for LaTeX and friends")
    (description
     "Rubber is a program whose purpose is to handle all tasks related to the
compilation of LaTeX documents.  This includes compiling the document itself,
of course, enough times so that all references are defined, and running BibTeX
to manage bibliographic references.  Automatic execution of dvips to produce
PostScript documents is also included, as well as usage of pdfLaTeX to produce
PDF documents.")
    (license license:gpl2+)))

(define-public texmaker
  (package
    (name "texmaker")
    (version "4.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.xm1math.net/texmaker/texmaker-"
                                  version ".tar.bz2"))
              (sha256
               (base32
                "056njk6j8wma23mlp7xa3rgfaxx0q8ynwx8wkmj7iy0b85p9ds9c"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; Qt has its own configuration utility.
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (zero? (system* "qmake"
                               (string-append "PREFIX=" out)
                               (string-append "DESKTOPDIR=" out
                                              "/share/applications")
                               (string-append "ICONDIR=" out "/share/pixmaps")
                               "texmaker.pro"))))))))
    (inputs
     `(("poppler-qt5" ,poppler-qt5)
       ("qtbase" ,qtbase)
       ("qtscript" ,qtscript)
       ("qtwebkit" ,qtwebkit)
       ("zlib" ,zlib)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://www.xm1math.net/texmaker/")
    (synopsis "LaTeX editor")
    (description "Texmaker is a program that integrates many tools needed to
develop documents with LaTeX, in a single application.")
    (license license:gpl2+)))


(define-public teximpatient
  (package
    (name "teximpatient")
    (version "2.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnu/" name "/" name "-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0h56w22d99dh4fgld4ssik8ggnmhmrrbnrn1lnxi1zr0miphn1sd"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'check)
         ;; Unfortunately some mistakes have been made in packaging.
         ;; Work around them here ...
         (replace 'unpack
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((srcdir "teximpatient-2.4"))
               (system* "tar" "-xzf" (assoc-ref inputs "source")
                        (string-append "--one-top-level=" srcdir))
               (delete-file (string-append srcdir "/book.pdf"))
               (install-file (car
                              (find-files
                               (assoc-ref inputs "automake")
                               "^install-sh$"))
                             srcdir)
               (chdir srcdir)))))))
    (native-inputs
     `(("texlive" ,texlive)
       ("automake" ,automake)))
    (home-page "https://www.gnu.org/software/teximpatient/")
    (synopsis "Book on TeX, plain TeX and Eplain")
    (description "@i{TeX for the Impatient} is a ~350 page book on TeX,
plain TeX, and Eplain, originally written by Paul Abrahams, Kathryn Hargreaves,
and Karl Berry.")
    (license license:fdl1.3+)))
