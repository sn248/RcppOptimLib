# RcppOptimLib

An R interface to [OptimLib](https://github.com/kthohr/optim), Keith
O’Hara’s header-only C++ library of numerical optimization methods for
nonlinear functions — BFGS, L-BFGS, conjugate gradient, gradient
descent, Newton, Nelder–Mead, differential evolution, particle swarm,
constrained optimization (SUMT) and root finding — built on the
Armadillo linear algebra library.

The OptimLib headers (header-only mode) are shipped in `inst/include/`,
so other R packages can use them by adding

    LinkingTo: RcppOptimLib, Rcpp, RcppArmadillo

to their `DESCRIPTION` and linking BLAS/LAPACK in `src/Makevars`
(required on Windows):

    PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)

or from a standalone C++ file:

``` cpp
// [[Rcpp::depends(RcppOptimLib, RcppArmadillo)]]
#include <RcppOptimLib.h>

double sphere_fn(const arma::vec& x, arma::vec* grad_out, void*) {
    if (grad_out) *grad_out = 2.0 * x;
    return arma::dot(x, x);
}

// [[Rcpp::export]]
arma::vec minimize_sphere(arma::vec x0) {
    optim::bfgs(x0, sphere_fn, nullptr);
    return x0;
}
```

From R, every algorithm is available on plain R functions through an
[`optim()`](https://rdrr.io/r/stats/optim.html)-like interface:

``` r

rosenbrock    <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(-400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
                                200 * (x[2] - x[1]^2))

optimlib(c(-1.2, 1), rosenbrock, rosenbrock_gr)                  # BFGS
optimlib(c(-1.2, 1), rosenbrock, method = "lbfgs",               # numeric gradient
         control = list(lbfgs = list(par_M = 5)))
optimlib(c(0.5, 0.5), rosenbrock, method = "nm",                 # box constraints
         lower = 0, upper = 0.8)

set.seed(1)                                                       # global search
optimlib(c(2, 2), rosenbrock, method = "pso", lower = -5, upper = 5)

optimlib_sumt(c(0, 0), function(x) sum((x - 2)^2),                # x1 + x2 <= 2
              constr = function(x) x[1] + x[2] - 2)
optimlib_root(c(1.2, 1.3), function(x) c(sum(x^2) - 4, x[1] - x[2]))
```

See
[`?optimlib_control`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md)
for the convergence and algorithm-specific settings.

See `IMPLEMENTATION.md` for the design decisions and the development
roadmap.

## License

RcppOptimLib is GPL (\>= 3). The bundled OptimLib and BaseMatrixOps
headers are Copyright Keith O’Hara, Apache License 2.0 — see
`inst/COPYRIGHTS`.
