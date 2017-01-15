;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Cyril Roelandt <tipecaml@gmail.com>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015 David Hashe <david.hashe@dhashe.com>
;;; Copyright © 2016 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016, 2017 Julien Lepiller <julien@lepiller.eu>
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

(define-module (gnu packages ocaml)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages lynx)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages time)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system ocaml)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix svn-download)
  #:use-module (guix utils))

;; A shortcut for files from ocaml forge. Downloaded files are computed from
;; their number, not their name.
(define (ocaml-forge-uri name version file-number)
  (string-append "https://forge.ocamlcore.org/frs/download.php/"
                 (number->string file-number) "/" name "-" version
                 ".tar.gz"))

(define-public ocaml
  (package
    (name "ocaml")
    (version "4.02.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://caml.inria.fr/pub/distrib/ocaml-"
                    (version-major+minor version)
                    "/ocaml-" version ".tar.xz"))
              (sha256
               (base32
                "1qwwvy8nzd87hk8rd9sm667nppakiapnx4ypdwcrlnav2dz6kil3"))
              (patches
               (search-patches
                "ocaml-CVE-2015-8869.patch"
                "ocaml-Add-a-.file-directive.patch"))))
    (build-system gnu-build-system)
    (native-search-paths
     (list (search-path-specification
            (variable "OCAMLPATH")
            (files (list "lib/ocaml" "lib/ocaml/site-lib")))
           (search-path-specification
            (variable "CAML_LD_LIBRARY_PATH")
            (files (list "lib/ocaml/site-lib/stubslibs")))))
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("libx11" ,libx11)
       ;; For libiberty, needed for objdump support.
       ("gcc:lib" ,(canonical-package gcc-4.9) "lib")
       ("zlib" ,zlib)))                       ;also needed for objdump support
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (web server))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-/bin/sh-references
           (lambda* (#:key inputs #:allow-other-keys)
             (let* ((sh (string-append (assoc-ref inputs "bash")
                                       "/bin/sh"))
                    (quoted-sh (string-append "\"" sh "\"")))
               (with-fluids ((%default-port-encoding #f))
                 (for-each
                  (lambda (file)
                    (substitute* file
                      (("\"/bin/sh\"")
                       (begin
                         (format (current-error-port) "\
patch-/bin/sh-references: ~a: changing `\"/bin/sh\"' to `~a'~%"
                                 file quoted-sh)
                         quoted-sh))))
                  (find-files "." "\\.ml$"))
                 #t))))
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (mandir (string-append out "/share/man")))
               ;; Custom configure script doesn't recognize
               ;; --prefix=<PREFIX> syntax (with equals sign).
               (zero? (system* "./configure"
                               "--prefix" out
                               "--mandir" mandir)))))
         (replace 'build
           (lambda _
             (zero? (system* "make" "-j" (number->string
                                          (parallel-job-count))
                             "world.opt"))))
         (delete 'check)
         (add-after 'install 'check
           (lambda _
             (with-directory-excursion "testsuite"
               (zero? (system* "make" "all")))))
         (add-before 'check 'prepare-socket-test
           (lambda _
             (format (current-error-port)
                     "Spawning local test web server on port 8080~%")
             (when (zero? (primitive-fork))
               (run-server (lambda (request request-body)
                             (values '((content-type . (text/plain)))
                                     "Hello!"))
                           'http '(#:port 8080)))
             (let ((file "testsuite/tests/lib-threads/testsocket.ml"))
               (format (current-error-port)
                       "Patching ~a to use localhost port 8080~%"
                       file)
               (substitute* file
                 (("caml.inria.fr") "localhost")
                 (("80") "8080")
                 (("HTTP1.0") "HTTP/1.0"))
               #t))))))
    (home-page "https://ocaml.org/")
    (synopsis "The OCaml programming language")
    (description
     "OCaml is a general purpose industrial-strength programming language with
an emphasis on expressiveness and safety.  Developed for more than 20 years at
Inria it benefits from one of the most advanced type systems and supports
functional, imperative and object-oriented styles of programming.")
    ;; The compiler is distributed under qpl1.0 with a change to choice of
    ;; law: the license is governed by the laws of France.  The library is
    ;; distributed under lgpl2.0.
    (license (list license:qpl license:lgpl2.0))))

(define-public opam
  (package
    (name "opam")
    (version "1.2.2")
    (source (origin
              (method url-fetch)
              ;; Use the '-full' version, which includes all the dependencies.
              (uri (string-append
                    "https://github.com/ocaml/opam/releases/download/"
                    version "/opam-full-" version ".tar.gz")
               ;; (string-append "https://github.com/ocaml/opam/archive/"
               ;;                    version ".tar.gz")
               )
              (sha256
               (base32
                "004gwn6rbpcb53y3rpb3v23vk39rp2xmf0liyd5iy12ij8bigrhm"))))
    (build-system gnu-build-system)
    (arguments
     '(;; Sometimes, 'make -jX' would fail right after ./configure with
       ;; "Fatal error: exception End_of_file".
       #:parallel-build? #f

       ;; For some reason, 'ocp-build' needs $TERM to be set.
       #:make-flags `("TERM=screen"
                      ,(string-append "SHELL="
                                      (assoc-ref %build-inputs "bash")
                                      "/bin/sh"))
       #:test-target "tests"

       ;; FIXME: There's an obscure test failure:
       ;;   …/_obuild/opam/opam.asm install P1' failed.
       #:tests? #f

       #:phases (modify-phases %standard-phases
                 (add-before 'build 'pre-build
                   (lambda* (#:key inputs make-flags #:allow-other-keys)
                     (let ((bash (assoc-ref inputs "bash")))
                       (substitute* "src/core/opamSystem.ml"
                         (("\"/bin/sh\"")
                          (string-append "\"" bash "/bin/sh\"")))
                       ;; Build dependencies
                       (zero? (apply system* "make" "lib-ext" make-flags)))))
                 (add-before 'check 'pre-check
                   (lambda _
                     (setenv "HOME" (getcwd))
                     (and (system "git config --global user.email guix@gnu.org")
                          (system "git config --global user.name Guix")))))))
    (native-inputs
     `(("git" ,git)                               ;for the tests
       ("python" ,python)                         ;for the tests
       ("camlp4" ,camlp4)))
    (inputs
     `(("ocaml" ,ocaml)
       ("ncurses" ,ncurses)
       ("curl" ,curl)))
    (home-page "http://opam.ocamlpro.com/")
    (synopsis "Package manager for OCaml")
    (description
     "OPAM is a tool to manage OCaml packages.  It supports multiple
simultaneous compiler installations, flexible package constraints, and a
Git-friendly development workflow.")

    ;; The 'LICENSE' file waives some requirements compared to LGPLv3.
    (license license:lgpl3)))

(define-public camlp4
  (package
    (name "camlp4")
    (version "4.02+6")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/ocaml/camlp4/archive/"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0icdfzhsbgf89925gc8gl3fm8z2xzszzlib0v9dj5wyzkyv3a342"))
              (file-name (string-append name "-" version ".tar.gz"))))
    (build-system gnu-build-system)
    (native-inputs `(("ocaml" ,ocaml)
                     ("which" ,which)))
    (inputs `(("ocaml" ,ocaml)))
    (arguments
     '(#:tests? #f                                ;no documented test target
       ;; a race-condition will lead byte and native targets to  mkdir _build
       ;; which  fails on the second attempt.
       #:parallel-build? #f
       #:make-flags '("all")
       #:phases (modify-phases %standard-phases
                  (replace
                   'configure
                   (lambda* (#:key outputs #:allow-other-keys)
                     ;; This is a home-made 'configure' script.
                     (let ((out (assoc-ref outputs "out")))
                       (zero? (system* "./configure"
                                       (string-append "--libdir=" out
                                                      "/lib/ocaml/site-lib")
                                       (string-append "--bindir=" out "/bin")
                                       (string-append "--pkgdir=" out
                                                      "/lib/ocaml/site-lib"))))))
                  (add-after 'install 'install-meta
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let ((out (assoc-ref outputs "out")))
                        (substitute* "camlp4/META.in"
                          (("directory = .*")
                            (string-append "directory = \"" out
                                           "/lib/ocaml/site-lib/camlp4\"\n")))
                        (zero? (system* "make" "install-META"))))))))
    (home-page "https://github.com/ocaml/camlp4")
    (synopsis "Write parsers in OCaml")
    (description
     "Camlp4 is a software system for writing extensible parsers for
programming languages.  It provides a set of OCaml libraries that are used to
define grammars as well as loadable syntax extensions of such grammars.
Camlp4 stands for Caml Preprocessor and Pretty-Printer and one of its most
important applications is the definition of domain-specific extensions of the
syntax of OCaml.")

    ;; This is LGPLv2 with an exception that allows packages statically-linked
    ;; against the library to be released under any terms.
    (license license:lgpl2.0)))

(define-public camlp5
  (package
    (name "camlp5")
    (version "6.14")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://camlp5.gforge.inria.fr/distrib/src/"
                                  name "-" version ".tgz"))
              (sha256
               (base32
                "1ql04iyvclpyy9805kpddc4ndjb5d0qg4shhi2fc6bixi49fvy89"))))
    (build-system gnu-build-system)
    (inputs
     `(("ocaml" ,ocaml)))
    (arguments
     `(#:tests? #f  ; XXX TODO figure out how to run the tests
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (mandir (string-append out "/share/man")))
                      ;; Custom configure script doesn't recognize
                      ;; --prefix=<PREFIX> syntax (with equals sign).
                      (zero? (system* "./configure"
                                      "--prefix" out
                                      "--mandir" mandir)))))
         (replace 'build
                  (lambda _
                    (zero? (system* "make" "-j" (number->string
                                                 (parallel-job-count))
                                    "world.opt")))))))
    (home-page "http://camlp5.gforge.inria.fr/")
    (synopsis "Pre-processor Pretty Printer for OCaml")
    (description
     "Camlp5 is a Pre-Processor-Pretty-Printer for Objective Caml.  It offers
tools for syntax (Stream Parsers and Grammars) and the ability to modify the
concrete syntax of the language (Quotations, Syntax Extensions).")
    ;; Most files are distributed under bsd-3, but ocaml_stuff/* is under qpl.
    (license (list license:bsd-3 license:qpl))))

(define-public hevea
  (package
    (name "hevea")
    (version "2.28")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://hevea.inria.fr/old/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "14fns13wlnpiv9i05841kvi3cq4b9v2sw5x3ff6ziws28q701qnd"))))
    (build-system gnu-build-system)
    (inputs
     `(("ocaml" ,ocaml)))
    (arguments
     `(#:tests? #f  ; no test suite
       #:make-flags (list (string-append "PREFIX=" %output))
       #:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (add-before 'build 'patch-/bin/sh
                    (lambda _
                      (substitute* "_tags"
                        (("/bin/sh") (which "sh")))
                      #t)))))
    (home-page "http://hevea.inria.fr/")
    (synopsis "LaTeX to HTML translator")
    (description
     "HeVeA is a LaTeX to HTML translator that generates modern HTML 5.  It is
written in Objective Caml.")
    (license license:qpl)))

(define-public coq
  (package
    (name "coq")
    (version "8.5pl2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://coq.inria.fr/distrib/V" version
                                  "/files/" name "-" version ".tar.gz"))
              (sha256
               (base32
                "0wyywia0darak2zmc5v0ra9rn0b9whwdfiahralm8v5za499s8w3"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("texlive" ,texlive)
       ("findlib" ,ocaml-findlib)
       ("hevea" ,hevea)))
    (inputs
     `(("ocaml" ,ocaml)
       ("lablgtk" ,lablgtk)
       ("camlp5" ,camlp5)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (mandir (string-append out "/share/man"))
                    (browser "icecat -remote \"OpenURL(%s,new-tab)\""))
               (zero? (system* "./configure"
                               "-prefix" out
                               "-mandir" mandir
                               "-browser" browser
                               "-coqide" "opt")))))
         (replace 'build
           (lambda _
             (zero? (system* "make" "-j" (number->string
                                          (parallel-job-count))
                             "world"))))
         (delete 'check)
         (add-after 'install 'check
           (lambda _
             (with-directory-excursion "test-suite"
               (zero? (system* "make"))))))))
    (home-page "https://coq.inria.fr")
    (synopsis "Proof assistant for higher-order logic")
    (description
     "Coq is a proof assistant for higher-order logic, which allows the
development of computer programs consistent with their formal specification.
It is developed using Objective Caml and Camlp5.")
    ;; The code is distributed under lgpl2.1.
    ;; Some of the documentation is distributed under opl1.0+.
    (license (list license:lgpl2.1 license:opl1.0+))))

(define-public proof-general
  (package
    (name "proof-general")
    (version "4.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://proofgeneral.inf.ed.ac.uk/releases/"
                    "ProofGeneral-" version ".tgz"))
              (sha256
               (base32
                "09qb0myq66fw17v4ziz401ilsb5xlxz1nl2wsp69d0vrfy0bcrrm"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("which" ,which)
       ("emacs" ,emacs-minimal)
       ("texinfo" ,texinfo)))
    (inputs
     `(("host-emacs" ,emacs)
       ("perl" ,perl)
       ("coq" ,coq)))
    (arguments
     `(#:tests? #f  ; no check target
       #:make-flags (list (string-append "PREFIX=" %output)
                          (string-append "DEST_PREFIX=" %output))
       #:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (guix build emacs-utils))
       #:imported-modules (,@%gnu-build-system-modules
                           (guix build emacs-utils))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'unpack 'disable-byte-compile-error-on-warn
                    (lambda _
                      (substitute* "Makefile"
                        (("\\(setq byte-compile-error-on-warn t\\)")
                         "(setq byte-compile-error-on-warn nil)"))
                      #t))
         (add-after 'unpack 'patch-hardcoded-paths
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (let ((out   (assoc-ref outputs "out"))
                            (coq   (assoc-ref inputs "coq"))
                            (emacs (assoc-ref inputs "host-emacs")))
                        (define (coq-prog name)
                          (string-append coq "/bin/" name))
                        (emacs-substitute-variables "coq/coq.el"
                          ("coq-prog-name"           (coq-prog "coqtop"))
                          ("coq-compiler"            (coq-prog "coqc"))
                          ("coq-dependency-analyzer" (coq-prog "coqdep")))
                        (substitute* "Makefile"
                          (("/sbin/install-info") "install-info"))
                        (substitute* "bin/proofgeneral"
                          (("^PGHOMEDEFAULT=.*" all)
                           (string-append all
                                          "PGHOME=$PGHOMEDEFAULT\n"
                                          "EMACS=" emacs "/bin/emacs")))
                        #t)))
         (add-after 'unpack 'clean
                    (lambda _
                      ;; Delete the pre-compiled elc files for Emacs 23.
                      (zero? (system* "make" "clean"))))
         (add-after 'install 'install-doc
                    (lambda* (#:key make-flags #:allow-other-keys)
                      ;; XXX FIXME avoid building/installing pdf files,
                      ;; due to unresolved errors building them.
                      (substitute* "Makefile"
                        ((" [^ ]*\\.pdf") ""))
                      (zero? (apply system* "make" "install-doc"
                                    make-flags)))))))
    (home-page "http://proofgeneral.inf.ed.ac.uk/")
    (synopsis "Generic front-end for proof assistants based on Emacs")
    (description
     "Proof General is a major mode to turn Emacs into an interactive proof
assistant to write formal mathematical proofs using a variety of theorem
provers.")
    (license license:gpl2+)))

(define-public ocaml-menhir
  (package
    (name "ocaml-menhir")
    (version "20161115")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://gallium.inria.fr/~fpottier/menhir/"
                    "menhir-" version ".tar.gz"))
              (sha256
               (base32
                "1j8nmcj2gq6hyyi16z27amiahplgrnk4ppchpm0v4qy80kwkf47k"))))
    (build-system gnu-build-system)
    (inputs
     `(("ocaml" ,ocaml)))
    (arguments
     `(#:parallel-build? #f ; Parallel build causes failure
       #:tests? #f ; No check target
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (setenv "PREFIX" out))
             #t)))))
    (home-page "http://gallium.inria.fr/~fpottier/menhir")
    (synopsis "Parser generator")
    (description "Menhir is a parser generator.  It turns high-level grammar
specifications, decorated with semantic actions expressed in the OCaml
programming language into parsers, again expressed in OCaml. It is based on
Knuth’s LR(1) parser construction technique.")
    ;; The file src/standard.mly and all files listed in src/mnehirLib.mlpack
    ;; that have an *.ml or *.mli extension are GPL licensed. All other files
    ;; are QPL licensed.
    (license (list license:gpl2+ license:qpl))))

(define-public lablgtk
  (package
    (name "lablgtk")
    (version "2.18.5")
    (source (origin
              (method url-fetch)
              (uri (ocaml-forge-uri name version 1627))
              (sha256
               (base32
                "0cyj6sfdvzx8hw7553lhgwc0krlgvlza0ph3dk9gsxy047dm3wib"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("camlp4" ,camlp4)
       ("ocaml" ,ocaml)
       ("findlib" ,ocaml-findlib)
       ("pkg-config" ,pkg-config)))
    ;; FIXME: Add inputs gtkgl-2.0, libpanelapplet-2.0, gtkspell-2.0,
    ;; and gtk+-quartz-2.0 once available.
    (inputs
     `(("gtk+" ,gtk+-2)
       ("gtksourceview" ,gtksourceview-2)
       ("libgnomecanvas" ,libgnomecanvas)
       ("libgnomeui" ,libgnomeui)
       ("libglade" ,libglade)
       ("librsvg" ,librsvg)))
    (arguments
     `(#:tests? #f ; no check target

       ;; opt: also install cmxa files
       #:make-flags (list "all" "opt"
                          (string-append "FINDLIBDIR="
                                         (assoc-ref %outputs "out")
                                         "/lib/ocaml"))
       ;; Occasionally we would get "Error: Unbound module GtkThread" when
       ;; compiling 'gtkThInit.ml', with 'make -j'.  So build sequentially.
       #:parallel-build? #f

       #:phases
         (modify-phases %standard-phases
           (add-before 'install 'prepare-install
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (let ((out (assoc-ref outputs "out"))
                     (ocaml (assoc-ref inputs "ocaml")))
                 ;; Install into the output and not the ocaml directory.
                 (mkdir-p (string-append out "/lib/ocaml"))
                 (substitute* "config.make"
                   ((ocaml) out))
                 #t))))))
    (home-page "http://lablgtk.forge.ocamlcore.org/")
    (synopsis "GTK+ bindings for OCaml")
    (description
     "LablGtk is an OCaml interface to GTK+ 1.2 and 2.x.  It provides
a strongly-typed object-oriented interface that is compatible with the
dynamic typing of GTK+.  Most widgets and methods are available.  LablGtk
also provides bindings to
gdk-pixbuf, the GLArea widget (in combination with LablGL), gnomecanvas,
gnomeui, gtksourceview, gtkspell,
libglade (and it an generate OCaml code from .glade files),
libpanel, librsvg and quartz.")
    (license license:lgpl2.1)))

(define-public unison
  (package
    (name "unison")
    (version "2.48.3")
    (source
      (origin
        (method svn-fetch)
        (uri (svn-reference
              (url (string-append "https://webdav.seas.upenn.edu/svn/"
                                  "unison/branches/"
                                  (version-major+minor version)))
              (revision 535)))
        (file-name (string-append name "-" version "-checkout"))
        (sha256
         (base32
          "0486s53wyayicj9f2raj2dvwvk4xyzar219rccc1iczdwixm4x05"))
        (modules '((guix build utils)
                   (ice-9 rdelim)
                   (ice-9 regex)
                   (srfi srfi-1)))
        (snippet
         `(begin
            ;; The svn revision in the release tarball appears to be
            ;; artificially manipulated in order to set the desired point
            ;; version number.  Because the point version is calculated during
            ;; the build, we can offset pointVersionOrigin by the desired
            ;; point version and write that into "Rev: %d".  We do this rather
            ;; than hardcoding the necessary revision number, for
            ;; maintainability.
            (with-atomic-file-replacement "src/mkProjectInfo.ml"
              (lambda (in out)
                (let ((pt-ver (string->number (third (string-split ,version #\.))))
                      (pt-rx  (make-regexp "^let pointVersionOrigin = ([0-9]+)"))
                      (rev-rx (make-regexp "Rev: [0-9]+")))
                  (let loop ((pt-origin #f))
                    (let ((line (read-line in 'concat)))
                      (cond
                       ((regexp-exec pt-rx line)
                        => (lambda (m)
                             (display line out)
                             (loop (string->number (match:substring m 1)))))
                       ((regexp-exec rev-rx line)
                        => (lambda (m)
                             (format out "~aRev: ~d~a"
                                     (match:prefix m)
                                     (+ pt-origin pt-ver)
                                     (match:suffix m))
                             (dump-port in out))) ;done
                       (else
                        (display line out)
                        (loop pt-origin))))))))
            ;; Without the '-fix' argument, the html file produced does not
            ;; have functioning internal hyperlinks.
            (substitute* "doc/Makefile"
              (("hevea unison") "hevea -fix unison"))))))
    (build-system gnu-build-system)
    (outputs '("out"
               "doc"))                  ; 1.9 MiB of documentation
    (native-inputs
     `(("ocaml" ,ocaml)
       ;; For documentation
       ("ghostscript" ,ghostscript)
       ("texlive" ,texlive)
       ("hevea" ,hevea)
       ("lynx" ,lynx)))
    (arguments
     `(#:parallel-build? #f
       #:parallel-tests? #f
       #:test-target "selftest"
       #:tests? #f ; Tests require writing to $HOME.
                   ; If some $HOME is provided, they fail with the message
                   ; "Fatal error: Skipping some tests -- remove me!"
       #:phases
         (modify-phases %standard-phases
           (delete 'configure)
           (add-before 'install 'prepare-install
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (bin (string-append out "/bin")))
                 (mkdir-p bin)
                 (setenv "HOME" out) ; forces correct INSTALLDIR in Makefile
                 #t)))
           (add-after 'install 'install-fsmonitor
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (bin (string-append out "/bin")))
                 ;; 'unison-fsmonitor' is used in "unison -repeat watch" mode.
                 (install-file "src/unison-fsmonitor" bin))))
           (add-after 'install 'install-doc
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((doc (string-append (assoc-ref outputs "doc")
                                         "/share/doc/unison")))
                 (mkdir-p doc)
                 ;; This file needs write-permissions, because it's
                 ;; overwritten by 'docs' during documentation generation.
                 (chmod "src/strings.ml" #o600)
                 (and (zero? (system* "make" "docs"
                                      "TEXDIRECTIVES=\\\\draftfalse"))
                      (begin
                        (for-each (lambda (f)
                                    (install-file f doc))
                                  (map (lambda (ext)
                                         (string-append
                                          "doc/unison-manual." ext))
                                       ;; Install only html documentation,
                                       ;; since the build is currently
                                       ;; non-reproducible with the ps, pdf,
                                       ;; and dvi docs.
                                       '(;;"ps" "pdf" "dvi"
                                         "html")))
                        #t))))))))
    (home-page "https://www.cis.upenn.edu/~bcpierce/unison/")
    (synopsis "File synchronizer")
    (description
     "Unison is a file-synchronization tool.  It allows two replicas of
a collection of files and directories to be stored on different hosts
(or different disks on the same host), modified separately, and then
brought up to date by propagating the changes in each replica
to the other.")
    (license license:gpl3+)))

(define-public ocaml-findlib
  (package
    (name "ocaml-findlib")
    (version "1.6.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://download.camlcity.org/download/"
                                  "findlib" "-" version ".tar.gz"))
              (sha256
               (base32
                "02abg1lsnwvjg3igdyb8qjgr5kv1nbwl4gaf8mdinzfii5p82721"))
              (patches (search-patches "ocaml-findlib-make-install.patch"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("camlp4" ,camlp4)
       ("m4" ,m4)
       ("ocaml" ,ocaml)))
    (arguments
     `(#:tests? #f  ; no test suite
       #:parallel-build? #f
       #:make-flags (list "all" "opt")
       #:phases (modify-phases %standard-phases
                  (replace
                   'configure
                   (lambda* (#:key inputs outputs #:allow-other-keys)
                     (let ((out (assoc-ref outputs "out")))
                       (system*
                        "./configure"
                        "-bindir" (string-append out "/bin")
                        "-config" (string-append out "/etc/ocamfind.conf")
                        "-mandir" (string-append out "/share/man")
                        "-sitelib" (string-append out "/lib/ocaml/site-lib")
                        "-with-toolbox"))))
                  (add-after 'install 'remove-camlp4
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let ((out (assoc-ref outputs "out")))
                        (delete-file-recursively
                          (string-append out "/lib/ocaml/site-lib/camlp4"))))))))
    (home-page "http://projects.camlcity.org/projects/findlib.html")
    (synopsis "Management tool for OCaml libraries")
    (description
     "The \"findlib\" library provides a scheme to manage reusable software
components (packages), and includes tools that support this scheme.  Packages
are collections of OCaml modules for which metainformation can be stored.  The
packages are kept in the file system hierarchy, but with strict directory
structure.  The library contains functions to look the directory up that
stores a package, to query metainformation about a package, and to retrieve
dependency information about multiple packages.  There is also a tool that
allows the user to enter queries on the command-line.  In order to simplify
compilation and linkage, there are new frontends of the various OCaml
compilers that can directly deal with packages.")
    (license license:x11)))

;; note that some tests may hang for no obvious reason.
(define-public ocaml-ounit
  (package
    (name "ocaml-ounit")
    (version "2.0.0")
    (source (origin
              (method url-fetch)
              (uri (ocaml-forge-uri "ounit" version 1258))
              (sha256
               (base32
                "118xsadrx84pif9vaq13hv4yh22w9kmr0ypvhrs0viir1jr0ajjd"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("libxml2" ,libxml2))) ; for xmllint
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; Tests are done during build.
         (delete 'check))))
    (home-page "http://ounit.forge.ocamlcore.org")
    (synopsis "Unit testing framework for OCaml")
    (description "Unit testing framework for OCaml.  It is similar to JUnit and
other XUnit testing frameworks.")
    (license license:expat)))

(define-public camlzip
  (package
    (name "camlzip")
    (version "1.0.6")
    (source (origin
              (method url-fetch)
              (uri (ocaml-forge-uri name version 1616))
              (sha256
               (base32
                "0m6gyjw46w3qnhxfsyqyag42znl5lwargks7w7rfchr9jzwpff68"))))
    (build-system ocaml-build-system)
    (inputs
     `(("zlib" ,zlib)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-before 'install 'fix-install-name
           (lambda* (#:key #:allow-other-keys)
             (substitute* "Makefile"
               (("install zip") "install camlzip")))))
       #:install-target "install-findlib"
       #:make-flags
       (list "all" "allopt"
             (string-append "INSTALLDIR=" (assoc-ref %outputs "out")
                            "/lib/ocaml"))))
    (home-page "http://forge.ocamlcore.org/projects/camlzip")
    (synopsis "Provides easy access to compressed files")
    (description "Provides easy access to compressed files in ZIP, GZIP and
JAR format.  It provides functions for reading from and writing to compressed
files in these formats.")
    (license license:lgpl2.1+)))

(define-public ocamlmod
  (package
    (name "ocamlmod")
    (version "0.0.8")
    (source (origin
              (method url-fetch)
              (uri (ocaml-forge-uri name version 1544))
              (sha256
               (base32
                "1w0w8lfyymvk300dv13gvhrddpcyknvyp4g2yvq2vaw7khkhjs9g"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("ounit" ,ocaml-ounit)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; Tests are done during build.
         (delete 'check))))
    (home-page "https://forge.ocamlcore.org/projects/ocamlmod")
    (synopsis "Generate modules from OCaml source files")
    (description "Generate modules from OCaml source files.")
    (license license:lgpl2.1+))) ; with an exception

(define-public ocaml-zarith
  (package
    (name "ocaml-zarith")
    (version "1.4.1")
    (source (origin
              (method url-fetch)
              (uri (ocaml-forge-uri "zarith" version 1574))
              (sha256
               (base32
                "0l36hzmfbvdai2kcgynh13vfdim5x2grnaw61fxqalyjm90c3di3"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("perl" ,perl)))
    (inputs
     `(("gmp" ,gmp)))
    (arguments
     `(#:tests? #f ; no test target
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key #:allow-other-keys)
             (zero? (system* "./configure")))))))
    (home-page "https://forge.ocamlcore.org/projects/zarith/")
    (synopsis "Implements arbitrary-precision integers")
    (description "Implements arithmetic and logical operations over
arbitrary-precision integers.  It uses GMP to efficiently implement arithmetic
over big integers. Small integers are represented as Caml unboxed integers,
for speed and space economy.")
    (license license:lgpl2.1+))) ; with an exception

(define-public ocaml-frontc
  (package
    (name "ocaml-frontc")
    (version "3.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.irit.fr/recherches/ARCHI/MARCH/"
                                  "frontc/Frontc-" version ".tgz"))
              (sha256
               (base32
                "16dz153s92dgbw1rrfwbhscy73did87kfmjwyh3qpvs748h1sc4g"))))
    (build-system ocaml-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'install 'install-meta
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (with-output-to-file
                   (string-append out "/lib/ocaml/frontc/META")
                 (lambda _
                   (display
                    (string-append
                     "description = \"Parser for the C language\"
version = \"" ,version "\"
requires = \"unix\"
archive(byte) = \"frontc.cma\"
archive(native) = \"frontc.cmxa\""))))
               (symlink (string-append out "/lib/ocaml/frontc")
                        (string-append out "/lib/ocaml/FrontC"))))))
       #:make-flags (list (string-append "PREFIX="
                                         (assoc-ref %outputs "out"))
                          "OCAML_SITE=$(LIB_DIR)/ocaml/")))
    (home-page "https://www.irit.fr/FrontC")
    (synopsis "C parser and lexer library")
    (description "FrontC is an OCAML library providing a C parser and lexer.
The result is a syntactic tree easy to process with usual OCAML tree management.
It provides support for ANSI C syntax, old-C K&R style syntax and the standard
GNU CC attributes.  It provides also a C pretty printer as an example of use.")
    (license license:lgpl2.1)))

(define-public ocaml-qtest
  (package
    (name "ocaml-qtest")
    (version "2.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/vincent-hugot/iTeML/"
                                  "archive/v" version ".tar.gz"))
              (sha256
               (base32
                "1n7x5l6h4j44f75wzgzjsjkq349i4gj707w1hr7fx84igxxfr6vl"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("findlib" ,ocaml-findlib)))
    (propagated-inputs
     `(("ounit" ,ocaml-ounit)))
    (arguments
     `(#:tests? #f ; No test target.
       #:make-flags
       (list (string-append "BIN=" (assoc-ref %outputs "out") "/bin"))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "https://github.com/vincent-hugot/iTeML")
    (synopsis "Inline (Unit) Tests for OCaml")
    (description "Qtest extracts inline unit tests written using a special
syntax in comments.  Those tests are then run using the oUnit framework and the
qcheck library.  The possibilities range from trivial tests -- extremely simple
to use -- to sophisticated random generation of test cases.")
    (license license:lgpl3+)))

(define-public ocaml-stringext
  (package
    (name "ocaml-stringext")
    (version "1.4.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/rgrinberg/stringext"
                                  "/archive/v" version ".tar.gz"))
              (sha256
               (base32
                "19g6lfn03iki9f8h91hi0yiqn0b3wkxyq08b3y23wgv6jw6mssfh"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("qtest" ,ocaml-qtest)))
    (home-page "https://github.com/rgrinberg/stringext")
    (synopsis "Extra string functions for OCaml")
    (description "Provides a single module named Stringext that provides a grab
bag of often used but missing string functions from the stdlib.  E.g, split,
full_split, cut, rcut, etc..")
    ;; the only mention of a license in this project is in its `opam' file
    ;; where it says `mit'.
    (license license:expat)))


(define-public ocaml-bisect
  (package
    (name "ocaml-bisect")
    (version "1.3")
    (source (origin
              (method url-fetch)
              (uri (ocaml-forge-uri "bisect" version 1051))
              (sha256
               (base32
                "0kcg2rh0qlkfpbv3nhcb75n62b04gbrz0zasq15ynln91zd5qrg0"))
              (patches
               (search-patches
                "ocaml-bisect-fix-camlp4-in-another-directory.patch"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("camlp4" ,camlp4)
       ("libxml2" ,libxml2)
       ("which" ,which)))
    (propagated-inputs
     `(("camlp4" ,camlp4)))
    (arguments
     `(#:test-target "tests"
       #:make-flags
       (list "all" (string-append "CAMLP4_LIBDIR="
                                  (assoc-ref %build-inputs "camlp4")
                                  "/lib/ocaml/site-lib/camlp4"))
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (zero? (system* "./configure" "-prefix"
                             (assoc-ref outputs "out"))))))))
    (home-page "http://bisect.x9c.fr")
    (synopsis "Code coverage tool for the OCaml language")
    (description "Bisect is a code coverage tool for the OCaml language.  It is
a camlp4-based tool that allows to instrument your application before running
tests.  After application execution, it is possible to generate a report in HTML
format that is the replica of the application source code annotated with code
coverage information.")
    (license license:gpl3+)))

(define-public ocaml-bitstring
  (package
    (name "ocaml-bitstring")
    (version "2.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/xguerin/bitstring"
                                  "/archive/v" version ".tar.gz"))
              (sha256
               (base32
                "0miw4banfpmx4kxrckpqr57b1fcmsqdmspyjx6gqjd4kghm4l7xj"))
              (patches (search-patches "ocaml-bitstring-fix-configure.patch"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("camlp4" ,camlp4)
       ("time" ,time)
       ("autoconf" ,autoconf)
       ("automake" ,automake)
       ("bisect" ,ocaml-bisect)))
    (propagated-inputs
     `(("camlp4" ,camlp4)))
    (arguments
     `(#:configure-flags
       (list "CAMLP4OF=camlp4of" "--enable-coverage")
       #:make-flags
       (list (string-append "BISECTLIB="
                            (assoc-ref %build-inputs "bisect")
                            "/lib/ocaml/site-lib")
             (string-append "OCAMLCFLAGS=-g -I "
                            (assoc-ref %build-inputs "camlp4")
                            "/lib/ocaml/site-lib/camlp4 -I "
                            "$(BISECTLIB)/bisect")
             (string-append "OCAMLOPTFLAGS=-g -I "
                            (assoc-ref %build-inputs "camlp4")
                            "/lib/ocaml/site-lib/camlp4 -I "
                            "$(BISECTLIB)/bisect"))
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'fix-configure
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "Makefile.in"
               (("@abs_top_builddir@")
                (string-append "@abs_top_builddir@:" (getenv "LIBRARY_PATH"))))
             (substitute* "configure"
               (("-/bin/sh") (string-append "-" (assoc-ref inputs "bash")
                                            "/bin/sh")))))
         (add-after 'install 'link-lib
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (stubs (string-append out
                                          "/lib/ocaml/site-lib/stubslibs"))
                    (lib (string-append out
                                        "/lib/ocaml/site-lib/bitstring")))
               (mkdir-p stubs)
               (symlink (string-append lib "/dllbitstring.so")
                        (string-append stubs "/dllbitstring.so"))))))))
    (home-page "https://github.com/xguerin/bitstring")
    (synopsis "Bitstrings and bitstring matching for OCaml")
    (description "Adds Erlang-style bitstrings and matching over bitstrings as
a syntax extension and library for OCaml.  You can use this module to both parse
and generate binary formats, files and protocols.  Bitstring handling is added
as primitives to the language, making it exceptionally simple to use and very
powerful.")
    (license license:isc)))

(define-public ocaml-result
  (package
    (name "ocaml-result")
    (version "1.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/janestreet/result"
                                  "/archive/" version ".tar.gz"))
              (sha256
               (base32
                "1pgpfsgvhxnh0i37fkvp9j8nadns9hz9iqgabj4dr519j2gr1xvw"))))
    (build-system ocaml-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "https://github.com/janestreet/result")
    (synopsis "Compatibility Result module")
    (description "Uses the new result type defined in OCaml >= 4.03 while
staying compatible with older version of OCaml should use the Result module
defined in this library.")
    (license license:bsd-3)))

(define-public ocaml-topkg
  (package
    (name "ocaml-topkg")
    (version "0.8.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://erratique.ch/software/topkg/releases/"
                                  "topkg-" version ".tbz"))
              (sha256
               (base32
                "18rrh6fmf708z7dd30amljmcgaypj3kk49jrmrj68r4wnw8004j8"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("opam" ,opam)))
    (propagated-inputs
     `(("result" ,ocaml-result)))
    (arguments
     `(#:tests? #f
       #:build-flags '("build")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "http://erratique.ch/software/topkg")
    (synopsis "Transitory OCaml software packager")
    (description "Topkg is a packager for distributing OCaml software. It
provides an API to describe the files a package installs in a given build
configuration and to specify information about the package's distribution,
creation and publication procedures.")
    (license license:isc)))

(define-public ocaml-rresult
  (package
    (name "ocaml-rresult")
    (version "0.5.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://erratique.ch/software/rresult/releases/"
                                  "rresult-" version ".tbz"))
              (sha256
               (base32
                "1xxycxhdhaq8p9vhwi93s2mlxjwgm44fcxybx5vghzgbankz9yhm"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("opam" ,opam)))
    (propagated-inputs
     `(("topkg" ,ocaml-topkg)))
    (arguments
     `(#:tests? #f
       #:build-flags '("build")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "http://erratique.ch/software/rresult")
    (synopsis "Result value combinators for OCaml")
    (description "Handle computation results and errors in an explicit and
declarative manner, without resorting to exceptions.  It defines combinators
to operate on the result type available from OCaml 4.03 in the standard
library.")
    (license license:isc)))

(define-public ocaml-mtime
  (package
    (name "ocaml-mtime")
    (version "0.8.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://erratique.ch/software/mtime/releases/"
                                  "mtime-" version ".tbz"))
              (sha256
               (base32
                "1hfx4ny2dkw6jf3jppz0640dafl5xgn8r2si9kpwzhmibal8qrah"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("opam" ,opam)))
    (propagated-inputs
     `(("topkg" ,ocaml-topkg)))
    (arguments
     `(#:tests? #f
       #:build-flags
       '("native=true" "native-dynlink=true" "jsoo=false")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "http://erratique.ch/software/mtime")
    (synopsis "Monotonic wall-clock time for OCaml")
    (description "Access monotonic wall-clock time.  It allows to measure time
spans without being subject to operating system calendar time adjustments.")
    (license license:isc)))

(define-public ocaml-cmdliner
  (package
    (name "ocaml-cmdliner")
    (version "0.9.8")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://erratique.ch/software/cmdliner/releases/"
                                  "cmdliner-" version ".tbz"))
              (sha256
               (base32
                "0hdxlkgiwjml9dpaa80282a8350if7mc1m6yz2mrd7gci3fszykx"))))
    (build-system ocaml-build-system)
    (native-inputs
     `(("opam" ,opam)))
    (arguments
     `(#:tests? #f
       #:build-flags '("native=true" "native-dynlink=true")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "http://erratique.ch/software/cmdliner")
    (synopsis "Declarative definition of command line interfaces for OCaml")
    (description "Cmdliner is a module for the declarative definition of command
line interfaces.  It provides a simple and compositional mechanism to convert
command line arguments to OCaml values and pass them to your functions.  The
module automatically handles syntax errors, help messages and UNIX man page
generation. It supports programs with single or multiple commands and respects
most of the POSIX and GNU conventions.")
    (license license:bsd-3)))
