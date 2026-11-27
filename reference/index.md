# Package index

## Package overview

- [`RcppOptimLib`](https://sn248.github.io/RcppOptimLib/reference/RcppOptimLib-package.md)
  [`RcppOptimLib-package`](https://sn248.github.io/RcppOptimLib/reference/RcppOptimLib-package.md)
  : RcppOptimLib: An Interface to the C++ Numerical Optimization Library
  'OptimLib'

## Optimizing R functions

Wrappers that minimize plain R functions via callbacks into OptimLib.

- [`optimlib_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_bfgs.md)
  : Minimize an R function with BFGS via callbacks
- [`optimlib_nm()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_nm.md)
  : Minimize an R function with Nelder-Mead via callbacks

## C++ objective demonstrations

Objectives written entirely in C++; the model for packages using
`LinkingTo: RcppOptimLib`.

- [`optim_sphere_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optim_sphere_bfgs.md)
  : Minimize the sphere function with BFGS (C++ objective)
- [`optim_ackley_de()`](https://sn248.github.io/RcppOptimLib/reference/optim_ackley_de.md)
  : Minimize the Ackley function with Differential Evolution (C++
  objective)
