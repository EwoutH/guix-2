;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages monitoring)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gd)
  #:use-module (gnu packages image)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages zip))

(define-public nagios
  (package
    (name "nagios")
    (version "4.2.4")
    ;; XXX: Nagios 4.2.x and later bundle a copy of AngularJS.
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://sourceforge/nagios/nagios-4.x/nagios-"
                    version "/nagios-" version ".tar.gz"))
              (sha256
               (base32
                "0w0blbwiw0ps04b7gkyyk89qkgwsxh6gydhmggbm1kl3ar3mq1dh"))
              (modules '((guix build utils)))
              (snippet
               ;; Ensure reproducibility.
               '(substitute* (find-files "cgi" "\\.c$")
                  (("__DATE__") "\"1970-01-01\"")
                  (("__TIME__") "\"00:00:00\"")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("unzip" ,unzip)))
    (inputs
     `(("zlib" ,zlib)
       ("libpng-apng" ,libpng)
       ("gd" ,gd)
       ("perl" ,perl)
       ("mailutils" ,mailutils)))
    (arguments
     '(#:configure-flags (list "--sysconfdir=/etc"

                               ;; 'include/locations.h.in' defines file
                               ;; locations, and many things go directly under
                               ;; LOCALSTATEDIR, hence the extra '/nagios'.
                               "--localstatedir=/var/nagios"

                               (string-append
                                "--with-mail="
                                (assoc-ref %build-inputs "mailutils")
                                "/bin/mail"))
       #:make-flags '("all")
       #:phases (modify-phases %standard-phases
                  (add-before 'build 'do-not-chown-to-nagios
                    (lambda _
                      ;; Makefiles do 'install -o nagios -g nagios', which
                      ;; doesn't work for us.
                      (substitute* (find-files "." "^Makefile$")
                        (("-o nagios -g nagios")
                         ""))
                      #t))
                  (add-before 'build 'do-not-create-sysconfdir
                    (lambda _
                      ;; Don't try to create /var upon 'make install'.
                      (substitute* "Makefile"
                        (("\\$\\(INSTALL\\).*\\$\\(LOGDIR\\).*$" all)
                         (string-append "# " all))
                        (("\\$\\(INSTALL\\).*\\$\\(CHECKRESULTDIR\\).*$" all)
                         (string-append "# " all))
                        (("chmod g\\+s.*" all)
                         (string-append "# " all)))
                      #t))
                  (add-before 'build 'set-html/php-directory
                    (lambda _
                      ;; Install HTML and PHP files under 'share/nagios/html'
                      ;; instead of just 'share/'.
                      (substitute* '("html/Makefile" "Makefile")
                        (("HTMLDIR=.*$")
                         "HTMLDIR = $(datarootdir)/nagios/html\n"))
                      #t)))
       #:tests? #f))                             ;no 'check' target or similar
    (home-page "https://www.nagios.org/")
    (synopsis "Host, service, and network monitoring program")
    (description
     "Nagios is a host, service, and network monitoring program written in C.
CGI programs are included to allow you to view the current status, history,
etc. via a Web interface.  Features include:

@itemize
@item Monitoring of network services (via SMTP, POP3, HTTP, PING, etc).
@item Monitoring of host resources (processor load, disk usage, etc.).
@item A plugin interface to allow for user-developed service monitoring
  methods.
@item Ability to define network host hierarchy using \"parent\" hosts,
  allowing detection of and distinction between hosts that are down
  and those that are unreachable.
@item Notifications when problems occur and get resolved (via email,
  pager, or user-defined method).
@item Ability to define event handlers for proactive problem resolution.
@item Automatic log file rotation/archiving.
@item Optional web interface for viewing current network status,
  notification and problem history, log file, etc.
@end itemize\n")
    (license license:gpl2)))
