;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages graph)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (guix build-system r)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages statistics)
  #:use-module (gnu packages xml))

(define-public igraph
  (package
    (name "igraph")
    (version "0.7.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://igraph.org/nightly/get/c/igraph-"
                           version ".tar.gz"))
       (sha256
        (base32
         "1pxh8sdlirgvbvsw8v65h6prn7hlm45bfsl1yfcgd6rn4w706y6r"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       (list "--with-external-glpk"
             "--with-external-blas"
             "--with-external-lapack")))
    (inputs
     `(("gmp" ,gmp)
       ("glpk" ,glpk)
       ("libxml2" ,libxml2)
       ("lapack" ,lapack)
       ("openblas" ,openblas)
       ("zlib" ,zlib)))
    (home-page "http://igraph.org")
    (synopsis "Network analysis and visualization")
    (description
     "This package provides a library for the analysis of networks and graphs.
It can handle large graphs very well and provides functions for generating
random and regular graphs, graph visualization, centrality methods and much
more.")
    (license license:gpl2+)))

(define-public python-igraph
  (package (inherit igraph)
    (name "python-igraph")
    (version "0.7.1.post6")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "python-igraph" version))
       (sha256
        (base32
         "0xp61zz710qlzhmzbfr65d5flvsi8zf2xy78s6rsszh719wl5sm5"))))
    (build-system python-build-system)
    (arguments '())
    (inputs
     `(("igraph" ,igraph)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://pypi.python.org/pypi/python-igraph")
    (synopsis "Python bindings for the igraph network analysis library")))

(define-public r-igraph
  (package
    (name "r-igraph")
    (version "1.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (cran-uri "igraph" version))
       (sha256
        (base32
         "1v26wyk52snh8z6m5p7yqwcd9dbqifhm57j112i9x53ppi0npcc9"))))
    (build-system r-build-system)
    (native-inputs
     `(("gfortran" ,gfortran)))
    (inputs
     `(("gmp" ,gmp)
       ("libxml2" ,libxml2)))
    (propagated-inputs
     `(("r-irlba" ,r-irlba)
       ("r-magrittr" ,r-magrittr)
       ("r-matrix" ,r-matrix)
       ("r-pkgconfig" ,r-pkgconfig)))
    (home-page "http://igraph.org")
    (synopsis "Network analysis and visualization")
    (description
     "This package provides routines for simple graphs and network analysis.
It can handle large graphs very well and provides functions for generating
random and regular graphs, graph visualization, centrality methods and much
more.")
    (license license:gpl2+)))
