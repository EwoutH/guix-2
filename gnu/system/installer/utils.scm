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

(define-module (gnu system installer utils)
  #:export (
	    justify*
	    addstr*
            slurp*
            slurp**
            key-value-slurp*
	    quit-key?

	    push-cursor
	    pop-cursor

	    make-window-port
	    standard-menu-keystrokes

	    make-boxed-window
            inner
            outer
            deep-visit-windows

	    open-input-pipe-with-fallback*

	    find-mount-device

	    window-pipe
            pipe-cmd
            refresh*

            scandir-with-slashes
            create-vbox
            boxed-window-decoration-refresh

	    select-key?))

(use-modules (ice-9 popen)
             (ice-9 ftw)
	     (ice-9 rdelim)
             (ice-9 match)
	     (ncurses menu)
	     (gnu system installer misc)
             (gnu system installer filesystems)
	     (ncurses form)
             (ncurses panel)
             (ncurses curses)
             (gurses colors))

(define (refresh* win)
  #f)

(define (make-window-port win)
  "Return a port which writes to the curses window WIN"

  ;; It is reasonable to assume that windows for which a soft-port
  ;; exists will have a lot of text sent to them and should therefore
  ;; be scrollable.
  (scrollok! win #t)

  (make-soft-port
   (vector
    (lambda (c) (addch win c))
    (lambda (s) (addstr win s))
    (lambda () ;; Note: This will lose the cursor position.
               (update-panels)
               (doupdate))
    #f
    #f)
   "w"))

(define* (window-pipe win cmd #:rest args)
  "Run CMD ARGS ... sending stdout and stderr to WIN.  Returns the exit status of CMD."
  (clear win)
  (let* ((windowp (make-window-port win))
         (result (apply pipe-cmd windowp cmd args)))
    (close-port windowp)
    result))

(define* (pipe-cmd ipipe cmd #:rest args)
  "Run CMD ARGS ... sending stdout and stderr to IPIPE.  Returns the exit status of CMD."
  (let* ((pipep (pipe))
	 (pid (primitive-fork)))
    (if (zero? pid)
	(begin
          (close-port (car pipep))
	  (redirect-port (cdr pipep) (current-output-port))
	  (redirect-port (cdr pipep) (current-error-port))
	  (apply execlp cmd args))
	(begin
	  (close-port (cdr pipep))
	  (let loop ((c (read-char (car pipep))))
	    (unless (eof-object? c)
              (display c ipipe)
              (force-output ipipe)
              (loop (read-char (car pipep)))))
          (close-port (car pipep))))
    (cdr (waitpid pid))))

(define (justify* text width)
  "A naive function to split a string into lines no more than width characters long.
This version assumes some external entity puts in the carriage returns."
  (define (justify' l n acc)
    (if (null? l)
	acc
	(let* ((word (car l))
	       (o (remainder n width))
	       (len (string-length word))
	       (appendage (cond ((zero? o)
				 (string-append word))

				((> (- width o) len)
				 (string-append " " word))

				(else
				 (string-append (make-string (- width o) #\space) word)))))

	  (justify'
	   (cdr l)

	   (+ n (string-length appendage))

	   (string-append acc appendage)))))

  (justify' (string-split text char-set:blank) 0  ""))


(define* (addstr* win str #:key (y 0) (x 0))
  "Call the curses addstr procedure passing STR to justify to the width of WIN"
  (addstr win (justify* str (getmaxx win)) #:y y #:x x))

(define (open-input-pipe* program . args)
  (apply open-pipe* OPEN_READ program args))

(define (open-input-pipe-with-fallback* program . args)
  "Kludge for testing"
  (let* ((subst (string-append (dirname (current-filename)) "/pipe-subst/"
                    (string-map (lambda (c) (case c
                                             ((#\space) #\%)
                                             ((#\/) #\,)
                                             (else c)))
                                (string-append program " " (string-join args " "))))))
    (if (and (not (eqv? 0 (geteuid)))
             (file-exists? subst))
	(open-input-pipe* "cat" subst)
	(apply open-input-pipe* program args))))

(define (slurp* program . args)
  (let ((port #f)
	(status #f)
	(result #f))
    (dynamic-wind (lambda () (set! port (apply open-input-pipe-with-fallback* program args)))
                  (lambda () (set! result (slurp-real port)))
                  (lambda () (set! status (close-pipe port))))
    (if (zero? (status:exit-val status))
	result
	#f)))

(define (slurp** surface program . args)
  ;; This probably doesn't work because the window port is a soft port.
  ;; pipe-cmd has a weird workaround for that.
  (parameterize ((current-error-port (make-window-port surface)))
    (let ((result (apply slurp* program args)))
      (force-output (current-error-port))
      (close-port (current-error-port))
      result)))

(define (key-value-slurp* program . args)
  "Slurp CMD, which is expected to give an output of key-value pairs -
each pair terminated with a newline and the key/value delimited with ="
  (map (lambda (x)
           (let ((idx (string-index x #\=)))
             (cons (string->symbol (string-fold
                                    (lambda (c acc)
                                      (string-append
                                       acc
                                       (make-string 1 (char-downcase c))))
                                    ""
                                    (substring x 0 idx)))
                   (substring x (1+ idx) (string-length x)))))
       (apply slurp* program args)))

(define (slurp-real port)
  "Return a list of strings from PORT, one per line.

Ignore blank lines."
  (let lp ((line-list '()))
    (let  ((l (read-line port)))
      (if (eof-object? l)
	  (reverse line-list)
	  (lp
           (if (string= l "") ;; Ignore blank lines
               line-list
               (cons l line-list)))))))



(define (quit-key? c)
  (or
   (eqv? c #\q)
   (eqv? c #\Q)
   (eqv? c #\esc)))

(define (select-key? c)
  (or
   (eqv? c #\nl)
   (eqv? c #\cr)
   (eqv? c KEY_ENTER)
   (eqv? c #\space)))




(define cursor-stack '())

(define (push-cursor c)
  (set! cursor-stack (cons (curs-set c) cursor-stack)))

(define (pop-cursor)
  (curs-set (car cursor-stack))
  (set! cursor-stack (cdr cursor-stack)))



(define (standard-menu-keystrokes ch menu)
  (let ((win (menu-win menu)))
    (cond
	((eqv? ch KEY_DOWN)
	 (menu-driver menu REQ_DOWN_ITEM)
	 )

	((eqv? ch KEY_UP)
	 (menu-driver menu REQ_UP_ITEM)
	 ))

    (refresh* win)))



(define (inner boxed-window)
  (match boxed-window
    ((inside . _)
     (if (not (window? inside))
         (error "~s is not a window" inside))
     inside)))

(define (outer boxed-window)
  (match boxed-window
    ((_ . outside)
     (if (not (window? outside))
         (error "~s is not a window" outside))
     outside)))

(define* (boxed-window-decoration-refresh pr title)
  (let ((win (outer pr)))
    ;(erase win)
    (select-color! win 'normal)
    (move win 0 0)
    ;(addstr win "X")
    (box win (acs-vline) (acs-hline))
    (if title
      (let ((title (string-append "[ " title " ]")))
        ;(move win 2 1)
        ;(hline win (acs-hline) (- (getmaxx win) 2))
        (select-color! win 'livery-title)
        (addstr win title #:y 0 #:x (round (/ (- (getmaxx win) (string-length title)) 2)))))
    (select-color! win 'normal)))

(define* (make-boxed-window orig height width starty startx #:key (title #f))
  "Create a window with a frame around it, and optionally a TITLE.  Returns a
pair whose car is the inner window and whose cdr is the frame."
  (let* ((win  (if orig
                   (derwin orig height width starty startx #:panel #t)
                   (newwin      height width starty startx #:panel #t)))
          (ystart (if title 1 1)))
    (let ((sw (derwin win (- (getmaxy win) ystart 1)
                      (- (getmaxx win) 2)
                      ystart 1 #:panel #t)))
      (bkgdset! sw (color 1 (dim #\space)))
      (boxed-window-decoration-refresh (cons sw win) title)
      ;(refresh* sw)
      ;; Return the inner and outer windows
      (cons sw win))))


(define (find-mount-device in mp)
  "Given the list of (device . mount-point) pairs MP which indicates intended
mounts return the device on which the path IN would be mounted."
  (define dir-sep #\/)

  (define (normalise-directory-path p)
    ;; Drop the last character if it is #\/
    ;; !!!even if that is the ONLY character!!!
    (if (positive? (string-length p))
	(let* ((last (1- (string-length p))))
	  (if (eqv? dir-sep (string-ref p last))
	      (string-drop-right p 1)
	      p))
	p))

  (define (pair->mp pr)
    (file-system-spec-mount-point (cdr pr)))

  (if (not (absolute-file-name? in))
      (error (format #f "Path is not absolute")))

  (let ((target	 (string-split (normalise-directory-path in) dir-sep))
	(paths
	 (map-in-order
	  (lambda (p)
	    (cons (car p)
		  (string-split (normalise-directory-path (pair->mp p)) dir-sep)))
	  (sort mp (lambda (x y) (string> (pair->mp x) (pair->mp y)))))))

    (let loop ((pp paths))
      (if (null? pp)
	  #f
	  (let* ((subject (cdar pp))
		 (len (min (length subject)
			   (length target))))
	    (if (and
		 (<= (length subject) (length target))
		 (equal? (list-head target len)
			 (list-head subject len)))
		(caar pp)
		(loop (cdr pp))))))))

(define (scandir-with-slashes dir)
  (map (lambda (name)
         (match (stat:type (stat (string-append dir "/" name)))
          ('directory (string-append name "/"))
          (_ name)))
    (scandir dir)))

(define (deep-visit-windows proc window)
  (let ((panels (panels-map identity)))
    (for-each
      (lambda (subwindow)
        (if (eq? (getparent subwindow) window)
          (deep-visit-windows proc subwindow)))
      panels))
  (proc window))

(define (create-vbox-i parent-window item-heights y)
  (if (null? item-heights)
      '()
      (let ((item-height (car item-heights))
            (maxx (getmaxx parent-window)))
        (cons (derwin parent-window item-height maxx y 0 #:panel #t)
              (create-vbox-i parent-window (cdr item-heights)
                             (+ y item-height))))))

(define (create-vbox parent-window . item-heights)
  (create-vbox-i parent-window item-heights 0))
