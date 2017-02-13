;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Federico Beffa <beffa@fbengineering.ch>
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

(define-module (guix import stackage)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (guix import json)
  #:use-module (guix import hackage)
  #:use-module (guix memoization)
  #:use-module (guix packages)
  #:use-module (guix upstream)
  #:use-module (guix ui)
  #:export (stackage->guix-package
            %stackage-updater))


;;;
;;; Stackage info fetcher and access functions
;;;

(define %stackage-url "http://www.stackage.org")

(define (lts-info-ghc-version lts-info)
  "Retruns the version of the GHC compiler contained in LTS-INFO."
  (match lts-info
    ((("snapshot" ("ghc" . version) _ _) _)  version)
    (_ #f)))

(define (lts-info-packages lts-info)
  "Retruns the alist of packages contained in LTS-INFO."
  (match lts-info
    ((_ ("packages" pkg ...)) pkg)
    (_ '())))

(define stackage-lts-info-fetch
  ;; "Retrieve the information about the LTS Stackage release VERSION."
  (memoize
   (lambda* (#:optional (version ""))
     (let* ((url (if (string=? "" version)
                     (string-append %stackage-url "/lts")
                     (string-append %stackage-url "/lts-" version)))
            (lts-info (json-fetch url)))
       (if lts-info
           (reverse lts-info)
           (leave (_ "LTS release version not found: ~A~%") version))))))

(define (stackage-package-name pkg-info)
  (assoc-ref pkg-info "name"))

(define (stackage-package-version pkg-info)
  (assoc-ref pkg-info "version"))

(define (lts-package-version pkgs-info name)
  "Return the version of the package with upstream NAME included in PKGS-INFO."
  (let ((pkg (find (lambda (pkg) (string=? (stackage-package-name pkg) name))
                   pkgs-info)))
    (stackage-package-version pkg)))


;;;
;;; Importer entry point
;;;

(define (hackage-name-version name version)
  (and version (string-append  name "@" version)))

(define* (stackage->guix-package package-name ; upstream name
                                 #:key
                                 (include-test-dependencies? #t)
                                 (lts-version "")
                                 (packages-info
                                  (lts-info-packages
                                   (stackage-lts-info-fetch lts-version))))
  "Fetch Cabal file for PACKAGE-NAME from hackage.haskell.org.  The retrieved
vesion corresponds to the version of PACKAGE-NAME specified in the LTS-VERSION
release at stackage.org.  Return the `package' S-expression corresponding to
that package, or #f on failure.  PACKAGES-INFO is the alist with the packages
included in the Stackage LTS release."
  (let* ((version (lts-package-version packages-info package-name))
         (name-version (hackage-name-version package-name version)))
    (if name-version
        (hackage->guix-package name-version
                               #:include-test-dependencies?
                               include-test-dependencies?)
        (leave (_ "package not found: ~A~%") package-name))))


;;;
;;; Updater
;;;

(define latest-lts-release
  (let ((pkgs-info (mlambda () (lts-info-packages (stackage-lts-info-fetch)))))
    (lambda* (package)
      "Return an <upstream-source> for the latest Stackage LTS release of
PACKAGE or #f it the package is not inlucded in the Stackage LTS release."
      (let* ((hackage-name (guix-package->hackage-name package))
             (version (lts-package-version (pkgs-info) hackage-name))
             (name-version (hackage-name-version hackage-name version)))
        (match (and=> name-version hackage-fetch)
          (#f (format (current-error-port)
                      "warning: failed to parse ~a~%"
                      (hackage-cabal-url hackage-name))
              #f)
          (_ (let ((url (hackage-source-url hackage-name version)))
               (upstream-source
                (package (package-name package))
                (version version)
                (urls (list url))))))))))

(define %stackage-updater
  (upstream-updater
   (name 'stackage)
   (description "Updater for Stackage LTS packages")
   (pred hackage-package?)
   (latest latest-lts-release)))

;;; stackage.scm ends here
