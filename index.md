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

From R, demonstration wrappers are available, including callback-based
minimization of plain R functions:

``` r

rosenbrock    <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(-400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
                                200 * (x[2] - x[1]^2))
optimlib_bfgs(rosenbrock, rosenbrock_gr, c(-1.2, 1))
#> $par [1] 1 1   $value ~0   $success TRUE

optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))   # derivative-free
optim_ackley_de(c(2, -2), seed = 42L)              # global, C++ objective
```

See `IMPLEMENTATION.md` for the design decisions and the development
roadmap.

## License

RcppOptimLib is GPL (\>= 3). The bundled OptimLib and BaseMatrixOps
headers are Copyright Keith O’Hara, Apache License 2.0 — see
`inst/COPYRIGHTS`.
