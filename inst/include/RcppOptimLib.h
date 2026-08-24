#ifndef RCPPOPTIMLIB_H
#define RCPPOPTIMLIB_H

// Use RcppArmadillo's Armadillo instead of a system Armadillo. OptimLib
// includes <RcppArmadillo.h> itself when this flag is set; without it the
// two Armadillo configurations mix and fail to link.
#ifndef OPTIM_USE_RCPP_ARMADILLO
#define OPTIM_USE_RCPP_ARMADILLO
#endif

// R's C API is single-threaded: OptimLib's OpenMP-parallelized routines
// (DE, PSO) must never call back into R from worker threads. OpenMP stays
// off unless a client package compiles with OpenMP flags AND uses pure
// C++ objectives; see the package documentation before overriding this.
#ifndef RCPPOPTIMLIB_ALLOW_OPENMP
#ifndef OPTIM_DONT_USE_OPENMP
#define OPTIM_DONT_USE_OPENMP
#endif
#endif

// Route all console output through R's console (CRAN policy). Armadillo
// defaults ARMA_COUT_STREAM to std::cout and RcppArmadillo does not
// override it; OptimLib's trace output goes through BMO_MATOPS_COUT,
// which otherwise resolves to arma::cout. Rcpp::Rcout is declared by
// RcppCommon.h before Armadillo is included, so these are safe here.
#ifndef ARMA_COUT_STREAM
#define ARMA_COUT_STREAM Rcpp::Rcout
#endif
#ifndef ARMA_CERR_STREAM
#define ARMA_CERR_STREAM Rcpp::Rcerr
#endif
#ifndef BMO_MATOPS_COUT
#define BMO_MATOPS_COUT Rcpp::Rcout
#endif

#include "optim.hpp"

#endif // RCPPOPTIMLIB_H
