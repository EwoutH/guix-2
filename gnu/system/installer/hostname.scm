;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016, 2017 John Darrington <jmd@gnu.org>
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

(define-module (gnu system installer hostname)
  #:use-module (gnu system installer page)
  #:use-module (gnu system installer misc)
  #:use-module (gnu system installer utils)
  #:use-module (guix ui)
  #:use-module (gurses form)
  #:use-module (gurses buttons)
  #:use-module (ncurses curses)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)

  #:export (valid-hostname?)
  #:export (make-host-name-page))

(include "i18n.scm")

(define max-length ((const 63)))

(define validator
  (let ((regexp (make-regexp "^[A-Za-z0-9][-A-Za-z0-9]{0,62}$")))
    (lambda (text)
      (regexp-exec regexp text))))

(define my-fields `((name   ,(M_ "Host Name") ,max-length ,validator)))

(define (valid-hostname? name)
  "Return #t iff NAME is a valid hostname as defined by RFC 1034"
  (and
   (positive? (string-length name))
   (string-match "^[0-9A-Za-z-]*$" name)
   (not (eq? (string-ref name 0) #\-))  ;; First char may not be '-'
   (<= (string-length name) max-length)))

(define (make-host-name-page parent  title)
  (make-page (page-surface parent)
             title
             host-name-refresh
             1
             #:activator host-name-activate-item))

(define (host-name-refresh page)
  (when (not (page-initialised? page))
    (host-name-init page)
    (page-set-initialised! page #t))

  (let ((form  (page-datum page 'form))
	(text-window (page-datum page 'text-window)))
    (clear text-window)
    (addstr*
     text-window
      (format
       #f
       (G_ "Enter the host name for the new system.  Only letters, digits and hyphens are allowed. The first character may not be a hyphen.  A maximum of ~a characters are allowed.")
       max-length))
    (refresh* text-window)
    (refresh* (outer (page-wwin page)))
    (refresh* (form-window form))))

(define (host-name-activate-item page item)
  (let ((form  (page-datum page 'form))
	(nav   (page-datum page 'navigation))
	(dev   (page-datum page 'device)))
  (match item
    ('default
      (set! host-name (form-get-value form 0))
      (page-leave)
      'handled)
    ('cancel
     (page-leave)
     'cancelled)
    (_ 'ignored))))

(define my-buttons `((cancel ,(M_ "Cancel") #f)))

(define (host-name-init p)
  (let* ((s (page-surface p))
	 (pr (make-boxed-window
	      #f
	      (- (getmaxy s) 4) (- (getmaxx s) 2)
	      2 1
	      #:title (page-title p)))

	 (text-window (derwin (inner pr) 5 (getmaxx (inner pr))
			      0 0 #:panel #f))

	 (bwin (derwin (inner pr)
		       3 (getmaxx (inner pr))
		       (- (getmaxy (inner pr)) 3) 0
		       #:panel #f))

	 (nav (make-buttons my-buttons 1))

	 (fw (derwin (inner pr)
		     2
		     (getmaxx (inner pr))
		     (getmaxy text-window) 0 #:panel #f))


	 (form (make-form my-fields)))

    (page-set-datum! p 'navigation nav)
    (page-set-datum! p 'text-window text-window)
    (page-set-datum! p 'form form)
    (push-cursor (page-cursor-visibility p))

    (form-post form fw)
    (buttons-post nav bwin)
    (page-set-wwin! p pr)
    (refresh* (outer pr))))

