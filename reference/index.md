# Package index

## Package overview

- [`RcppOptimLib`](https://sn248.github.io/RcppOptimLib/reference/RcppOptimLib-package.md)
  [`RcppOptimLib-package`](https://sn248.github.io/RcppOptimLib/reference/RcppOptimLib-package.md)
  : RcppOptimLib: An Interface to the C++ Numerical Optimization Library
  'OptimLib'

## Optimizing R functions

Minimize, constrain or solve plain R functions with any OptimLib
algorithm.

- [`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md)
  : Minimize an R function with OptimLib
- [`optimlib_sumt()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_sumt.md)
  : Minimize an R function subject to nonlinear inequality constraints
- [`optimlib_root()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_root.md)
  : Solve a system of nonlinear equations
- [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md)
  : Control settings for OptimLib algorithms

## Shortcuts

- [`optimlib_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_bfgs.md)
  : Minimize an R function with BFGS
- [`optimlib_nm()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_nm.md)
  : Minimize an R function with Nelder-Mead

## C++ objective demonstrations

Objectives written entirely in C++; the model for packages using
`LinkingTo: RcppOptimLib`.

- [`optim_sphere_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optim_sphere_bfgs.md)
  : Minimize the sphere function with BFGS (C++ objective)
- [`optim_ackley_de()`](https://sn248.github.io/RcppOptimLib/reference/optim_ackley_de.md)
  : Minimize the Ackley function with Differential Evolution (C++
  objective)
