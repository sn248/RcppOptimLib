# RcppOptimLib: An Interface to the C++ Numerical Optimization Library 'OptimLib'

Ships the header-only version of Keith O'Hara's 'OptimLib'
(<https://optimlib.readthedocs.io/>) so that R users and other R
packages can use its optimization algorithms (BFGS, L-BFGS, conjugate
gradient, gradient descent, Nelder-Mead, differential evolution,
particle swarm, and root finding) from C++ code via 'Rcpp' and
'RcppArmadillo'.

## Details

There are two ways to use the package:

1.  **From C++ (recommended):** add
    `LinkingTo: RcppOptimLib, Rcpp, RcppArmadillo` to your package's
    DESCRIPTION and `PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)` to
    its `src/Makevars` (or use
    `// [[Rcpp::depends(RcppOptimLib, RcppArmadillo)]]` in a
    `sourceCpp()` file), then `#include <RcppOptimLib.h>` and call the
    `optim::` routines directly on Armadillo vectors.

2.  **From R:**
    [`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md)
    minimizes plain R functions with any OptimLib algorithm,
    [`optimlib_sumt()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_sumt.md)
    adds nonlinear inequality constraints and
    [`optimlib_root()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_root.md)
    solves systems of equations; tune them with
    [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md).
    [`optim_sphere_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optim_sphere_bfgs.md)
    and
    [`optim_ackley_de()`](https://sn248.github.io/RcppOptimLib/reference/optim_ackley_de.md)
    demonstrate objectives written in C++.

## See also

Useful links:

- <https://github.com/sn248/RcppOptimLib>

- <https://sn248.github.io/RcppOptimLib/>

- Report bugs at <https://github.com/sn248/RcppOptimLib/issues>

## Author

**Maintainer**: Satyaprakash Nayak <satyaprakash.nayak@gmail.com>
([ORCID](https://orcid.org/0000-0001-7225-1317))

Authors:

- Satyaprakash Nayak <satyaprakash.nayak@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-7225-1317))

- Keith O'Hara (Author of the OptimLib C++ library) \[copyright holder\]
