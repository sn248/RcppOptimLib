# Changelog

## RcppOptimLib (development version)

- New
  [`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md),
  a general [`optim()`](https://rdrr.io/r/stats/optim.html)-style
  interface that minimizes plain R functions with any of OptimLib’s
  unconstrained algorithms: BFGS, L-BFGS, conjugate gradient, gradient
  descent (including Adam and related variants), Newton, Nelder-Mead,
  differential evolution (and DE-PRMM) and particle swarm (and PSO-DV).
  Supports box constraints, `...` arguments, and finite-difference
  gradients and Hessians when none are supplied. Population methods draw
  their seed from R’s RNG, so
  [`set.seed()`](https://rdrr.io/r/base/Random.html) makes them
  reproducible.
- New
  [`optimlib_sumt()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_sumt.md)
  for minimization under nonlinear inequality constraints, and
  [`optimlib_root()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_root.md)
  for systems of nonlinear equations (Broyden’s method).
- New
  [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md)
  exposes OptimLib’s convergence and algorithm-specific settings, with
  validation of names and values.
- [`optimlib_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_bfgs.md)
  and
  [`optimlib_nm()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_nm.md)
  are now shortcuts for
  [`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md);
  their results gain `error` and `method` elements, and callbacks now
  receive a plain numeric vector instead of a one-column matrix.
- Fixed three bugs in the bundled OptimLib headers: L-BFGS stalled after
  two iterations on non-quadratic problems, PSO-DV failed at runtime
  when a particle stagnated, and SUMT used an incorrect penalty gradient
  and stopped short of the constrained optimum.

## RcppOptimLib 0.0.1

- Initial CRAN submission.
