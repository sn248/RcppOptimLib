# RcppOptimLib (development version)

* New `optimlib()`, a general `optim()`-style interface that minimizes plain R functions with any of OptimLib's unconstrained algorithms: BFGS, L-BFGS, conjugate gradient, gradient descent (including Adam and related variants), Newton, Nelder-Mead, differential evolution (and DE-PRMM) and particle swarm (and PSO-DV). Supports box constraints, `...` arguments, and finite-difference gradients and Hessians when none are supplied. Population methods draw their seed from R's RNG, so `set.seed()` makes them reproducible.
* New `optimlib_sumt()` for minimization under nonlinear inequality constraints, and `optimlib_root()` for systems of nonlinear equations (Broyden's method).
* New `optimlib_control()` exposes OptimLib's convergence and algorithm-specific settings, with validation of names and values.
* `optimlib_bfgs()` and `optimlib_nm()` are now shortcuts for `optimlib()`; their results gain `error` and `method` elements, and callbacks now receive a plain numeric vector instead of a one-column matrix.
* Fixed three bugs in the bundled OptimLib headers: L-BFGS stalled after two iterations on non-quadratic problems, PSO-DV failed at runtime when a particle stagnated, and SUMT used an incorrect penalty gradient and stopped short of the constrained optimum.

# RcppOptimLib 0.0.1

* Initial CRAN submission.
