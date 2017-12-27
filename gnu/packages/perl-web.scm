;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2017 Tobias Geerinckx-Rice <me@tobias.gr>
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

(define-module (gnu packages perl-web)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system perl))

(define-public perl-mojolicious
  (package
    (name "perl-mojolicious")
    (version "7.59")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/S/SR/SRI/Mojolicious-"
                           version ".tar.gz"))
       (sha256
        (base32
         "11whfrbafj191ahbhlhadws0vkg9kmvqswzkvswgwajhr1x678rh"))))
    (build-system perl-build-system)
    (home-page "http://mojolicious.org/")
    (synopsis "Real-time web framework")
    (description "Back in the early days of the web, many people learned Perl
because of a wonderful Perl library called @code{CGI}.  It was simple enough
to get started without knowing much about the language and powerful enough to
keep you going, learning by doing was much fun.  While most of the techniques
used are outdated now, the idea behind it is not.  Mojolicious is a new
endeavor to implement this idea using modern technologies.")
    (license license:artistic2.0)))
