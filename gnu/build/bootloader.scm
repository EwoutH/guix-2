;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Mathieu Othacehe <m.othacehe@gmail.com>
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

(define-module (gnu build bootloader)
  #:use-module (ice-9 binary-ports)
  #:export (write-file-on-device))


;;;
;;; Writing utils.
;;;

(define (write-file-on-device file size device offset)
  "Write SIZE bytes from FILE to DEVICE starting at OFFSET."
  (call-with-input-file file
    (lambda (input)
      (let ((bv (get-bytevector-n input size)))
        (call-with-output-file device
          (lambda (output)
            (seek output offset SEEK_SET)
            (put-bytevector output bv))
          #:binary #t)))))
