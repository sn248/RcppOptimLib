# Introduction to RcppOptimLib

`RcppOptimLib` ships the header-only version of
[OptimLib](https://github.com/kthohr/optim), a C++ library of local and
global optimization algorithms built on Armadillo. There are two ways to
use it.

## 1. From R, via callbacks

The demonstration wrappers accept plain R functions. BFGS on the
Rosenbrock function, with an analytic gradient:

``` r

rosenbrock    <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(-400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
                                200 * (x[2] - x[1]^2))
optimlib_bfgs(rosenbrock, rosenbrock_gr, c(-1.2, 1))
#> $par
#> [1] 1 1
#> 
#> $value
#> [1] 2.233623e-18
#> 
#> $iterations
#> [1] 31
#> 
#> $success
#> [1] TRUE
```

Derivative-free Nelder–Mead needs no gradient:

``` r

optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))
#> $par
#> [1] 3 3
#> 
#> $value
#> [1] 2.481919e-15
#> 
#> $iterations
#> [1] 66
#> 
#> $success
#> [1] TRUE
```

Every objective evaluation crosses the R/C++ boundary, so for
performance-critical work write the objective in C++ (below).

## 2. From C++, via LinkingTo

Add `LinkingTo: RcppOptimLib, Rcpp, RcppArmadillo` to your package and
`PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)` to its `src/Makevars`
(Armadillo needs BLAS/LAPACK; the link fails on Windows without it), or
compile a standalone file with
[`Rcpp::sourceCpp()`](https://rdrr.io/pkg/Rcpp/man/sourceCpp.html),
where the `RcppArmadillo` plugin adds these libraries for you:

``` cpp
// [[Rcpp::depends(RcppOptimLib, RcppArmadillo)]]
#include <RcppOptimLib.h>

double sphere_fn(const arma::vec& x, arma::vec* grad_out, void*) {
    if (grad_out) *grad_out = 2.0 * x;
    return arma::dot(x, x);
}

// [[Rcpp::export]]
Rcpp::List minimize_sphere(arma::vec x0) {
    optim::algo_settings_t settings;
    bool ok = optim::bfgs(x0, sphere_fn, nullptr, settings);
    return Rcpp::List::create(
        Rcpp::Named("par") = Rcpp::NumericVector(x0.begin(), x0.end()),
        Rcpp::Named("value") = settings.opt_fn_value,
        Rcpp::Named("success") = ok);
}
```

The
[`optim_sphere_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optim_sphere_bfgs.md)
and
[`optim_ackley_de()`](https://sn248.github.io/RcppOptimLib/reference/optim_ackley_de.md)
exports in this package are compiled examples of exactly this pattern —
see `src/examples.cpp`. Differential evolution on the multimodal Ackley
function, with box bounds and a reproducible seed:

``` r

optim_ackley_de(c(2, -2), seed = 42L)
#> $par
#> [1]  0.000000e+00 -2.775558e-16
#> 
#> $value
#> [1] 4.440892e-16
#> 
#> $iterations
#> [1] 1001
#> 
#> $success
#> [1] TRUE
```

## Notes

- `#include <RcppOptimLib.h>` sets `OPTIM_USE_RCPP_ARMADILLO` for you;
  never include OptimLib’s `optim.hpp` directly.
- OpenMP is disabled by default because R callbacks must not run on
  worker threads; see `IMPLEMENTATION.md` in the package sources before
  opting back in for pure C++ objectives.
- OptimLib uses its own RNG (`std::mt19937_64`), so
  [`set.seed()`](https://rdrr.io/r/base/Random.html) has no effect on
  stochastic algorithms — pass a seed explicitly.
