
;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 John Darrington <jmd@gnu.org>
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

(define-module (gnu system installer role)
  #:use-module (gnu system installer page)
  #:use-module (gnu system installer misc)
  #:use-module (gnu system installer utils)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:use-module (gurses menu)
  #:use-module (gurses buttons)
  #:use-module (ncurses curses)
  #:use-module (srfi srfi-9)

  #:export (role-services)
  #:export (role-packages)
  #:export (role-package-modules)
  #:export (role-service-modules)
  #:export (role?)
  #:export (make-role-page))

(include "i18n.scm")

(define-record-type <role>
  (make-role description packages package-modules services service-modules)
  role?
  (description role-description)
  (packages role-packages)
  (package-modules role-package-modules)
  (services role-services)
  (service-modules role-service-modules))


(define (make-role-page parent title)
  (make-page (page-surface parent)
             title
             role-page-refresh
             0
             #:activator role-page-activate-item))

(define my-buttons `((cancel ,(M_ "Canc_el") #t)))

(define (role-page-activate-item page item)
  (match item
   (('menu-item-activated r)
    (set! system-role r)
    (page-leave)
    'handled)
   ('cancel
    (page-leave)
    'cancelled)
   (_ 'ignored)))

(define (role-page-refresh page)
  (when (not (page-initialised? page))
    (role-page-init page)
    (page-set-initialised! page #t))
  (let ((text-window (page-datum page 'text-window)))
    (erase text-window)
    (addstr*   text-window  (format #f (gettext "Select from the list below the role which most closely matches the purpose of the system to be installed.")))))

(define roles `(,(make-role (M_ "Headless server")
                            `(tcpdump)
                            `(admin)
                            `((dhcp-client-service)
                              (lsh-service #:port-number 2222)
                              %base-services)
                            `(networking ssh))
                ,(make-role (M_ "Lightweight desktop or laptop")
                            `(ratpoison i3-wm xmonad nss-certs)
                            `(wm ratpoison certs)
                            `(%desktop-services)
                            `(desktop))
                ,(make-role (M_ "Heavy duty workstation")
                            `(nss-certs gvfs)
                            `(certs gnome)
                            `((gnome-desktop-service)
                              (xfce-desktop-service)
                              %desktop-services)
                            `(desktop))))

(define (role-page-init p)
  (match (create-vbox (page-surface p) 5 (- (getmaxy (page-surface p)) 5 3) 3)
   ((text-window mwin bwin)
    (let* ((buttons (make-buttons my-buttons))
           (menu (make-menu roles
                          #:disp-proc (lambda (datum row)
                                        (gettext (role-description datum))))))
      (push-cursor (page-cursor-visibility p))
      (page-set-datum! p 'menu menu)
      (page-set-datum! p 'navigation buttons)
      (page-set-datum! p 'text-window text-window)
      (menu-post menu mwin)
      (buttons-post buttons bwin)))))
