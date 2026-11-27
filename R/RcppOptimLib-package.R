#' RcppOptimLib: An Interface to the C++ Numerical Optimization Library
#' 'OptimLib'
#'
#' Ships the header-only version of Keith O'Hara's 'OptimLib'
#' (<https://optimlib.readthedocs.io/>) so that R users and other R
#' packages can use its optimization algorithms (BFGS, L-BFGS, conjugate
#' gradient, gradient descent, Nelder-Mead, differential evolution,
#' particle swarm, and root finding) from C++ code via 'Rcpp' and
#' 'RcppArmadillo'.
#'
#' There are two ways to use the package:
#'
#' 1. **From C++ (recommended):** add `LinkingTo: RcppOptimLib, Rcpp,
#'    RcppArmadillo` to your package's DESCRIPTION and
#'    `PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)` to its
#'    `src/Makevars` (or use
#'    `// [[Rcpp::depends(RcppOptimLib, RcppArmadillo)]]` in a
#'    `sourceCpp()` file), then `#include <RcppOptimLib.h>` and call the
#'    `optim::` routines directly on Armadillo vectors.
#' 2. **From R:** call the demonstration wrappers such as
#'    [optim_sphere_bfgs()], [optim_ackley_de()], [optimlib_bfgs()] and
#'    [optimlib_nm()]. The latter two accept plain R functions as
#'    objectives via callbacks.
#'
#' @useDynLib RcppOptimLib, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @keywords internal
"_PACKAGE"
