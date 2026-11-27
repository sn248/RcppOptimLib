# Introduction to RcppOptimLib

`RcppOptimLib` ships the header-only version of
[OptimLib](https://github.com/kthohr/optim), a C++ library of local and
global optimization algorithms built on Armadillo. There are two ways to
use it.

## 1. From R, via callbacks

[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md)
minimizes a plain R function with any OptimLib algorithm, with an
interface modelled on [`optim()`](https://rdrr.io/r/stats/optim.html).
BFGS on the Rosenbrock function, with an analytic gradient:

``` r

rosenbrock    <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(-400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
                                200 * (x[2] - x[1]^2))
optimlib(c(-1.2, 1), rosenbrock, rosenbrock_gr)
#> $par
#> [1] 1 1
#> 
#> $value
#> [1] 2.233623e-18
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 31
#> 
#> $error
#> [1] 4.734761e-09
#> 
#> $method
#> [1] "bfgs"
```

Choose the algorithm with `method`. Gradient-based methods fall back to
finite differences when `gr` is omitted; Nelder–Mead, differential
evolution and particle swarm need no gradient at all:

``` r

sapply(c("lbfgs", "cg", "nm"), function(m) {
  optimlib(c(-1.2, 1), rosenbrock, method = m)$par
})
#>      lbfgs cg nm
#> [1,]     1  1  1
#> [2,]     1  1  1
```

Bounds are given with `lower` and `upper`. The population methods use
R’s random number generator for their seed, so
[`set.seed()`](https://rdrr.io/r/base/Random.html) makes them
reproducible:

``` r

set.seed(3016)
optimlib(c(2, 2), rosenbrock, method = "de", lower = -5, upper = 5,
         control = list(de = list(n_gen = 300)))$par
#> [1] 1 1
```

`control` takes general settings (`iter_max`, tolerances, `print_level`)
and per-algorithm lists such as `lbfgs = list(par_M = 20)` or
`gd = list(method = "adam")`; see
[`?optimlib_control`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md).
Nonlinear inequality constraints `g(x) <= 0` are handled by
[`optimlib_sumt()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_sumt.md),
and systems of equations by
[`optimlib_root()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_root.md):

``` r

optimlib_sumt(c(0, 0), function(x) sum((x - 2)^2),
              constr = function(x) sum(x^2) - 1)$par
#> [1] 0.7071068 0.7071068
optimlib_root(c(1.2, 1.3), function(x) c(sum(x^2) - 4, x[1] - x[2]))$par
#> [1] 1.414214 1.414214
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
