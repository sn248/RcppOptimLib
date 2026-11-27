# Minimize an R function with OptimLib

A general interface to OptimLib's unconstrained and box-constrained
minimizers, modelled on
[`stats::optim()`](https://rdrr.io/r/stats/optim.html). The objective
(and gradient / Hessian, if supplied) are plain R functions called from
C++.

## Usage

``` r
optimlib(
  par,
  fn,
  gr = NULL,
  ...,
  method = c("bfgs", "lbfgs", "cg", "gd", "newton", "nm", "de", "de_prmm", "pso",
    "pso_dv"),
  lower = -Inf,
  upper = Inf,
  hess = NULL,
  control = list()
)
```

## Arguments

- par:

  Numeric vector of starting values.

- fn:

  Objective function to minimize. Called as `fn(par, ...)` and must
  return a single number.

- gr:

  Gradient of `fn`, called as `gr(par, ...)` and returning a numeric
  vector of length `length(par)`. If `NULL`, gradient-based methods use
  central finite differences. Ignored by derivative-free methods.

- ...:

  Further arguments passed to `fn`, `gr` and `hess`.

- method:

  The algorithm:

  - `"bfgs"`: BFGS quasi-Newton.

  - `"lbfgs"`: limited-memory BFGS, for many parameters.

  - `"cg"`: nonlinear conjugate gradient.

  - `"gd"`: gradient descent, including momentum, Nesterov, AdaGrad,
    RMSProp, AdaDelta, Adam and Nadam variants (see `gd$method` in
    [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md)).

  - `"newton"`: Newton's method; uses `hess`. Does not support bounds.

  - `"nm"`: Nelder-Mead (derivative-free).

  - `"de"`, `"de_prmm"`: differential evolution, and its variant with
    population reduction and multiple mutation strategies
    (derivative-free, global).

  - `"pso"`, `"pso_dv"`: particle swarm optimization, and its
    differentially perturbed velocity variant (derivative-free, global).

- lower, upper:

  Bounds on the parameters, recycled to `length(par)`. Use `-Inf` /
  `Inf` for unbounded parameters. OptimLib handles bounds by
  transforming the parameters, so `par` must lie strictly inside them.

- hess:

  Hessian of `fn` for `method = "newton"`, called as `hess(par, ...)`
  and returning a `length(par)` x `length(par)` matrix. If `NULL`, it is
  approximated by finite differences of the gradient.

- control:

  A list of settings, or the result of
  [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md).

## Value

A list with elements:

- `par`: the best parameter values found.

- `value`: `fn` evaluated at `par`.

- `success`: `TRUE` if OptimLib reports convergence. For the population
  methods this is only meaningful when `check_freq` (in `de` / `pso` of
  [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md))
  is finite: with the default `check_freq = Inf` no convergence test is
  run, and OptimLib reports `TRUE` for `"de"` but `FALSE` for
  `"de_prmm"`, `"pso"` and `"pso_dv"` after `n_gen` generations. Judge
  those results by `value`.

- `iterations`: number of iterations (generations for population
  methods).

- `error`: the final value of the convergence criterion.

- `method`: the method used.

## See also

[`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md),
[`optimlib_sumt()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_sumt.md)
for nonlinear inequality constraints,
[`optimlib_root()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_root.md)
for systems of equations.

## Examples

``` r
rosenbrock <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(
  -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
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
#> 
optimlib(c(-1.2, 1), rosenbrock, rosenbrock_gr, method = "lbfgs")
#> $par
#> [1] 1 1
#> 
#> $value
#> [1] 9.268971e-22
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 36
#> 
#> $error
#> [1] 1.067933e-09
#> 
#> $method
#> [1] "lbfgs"
#> 
optimlib(c(-1.2, 1), rosenbrock, method = "nm")
#> $par
#> [1] 1 1
#> 
#> $value
#> [1] 3.083427e-14
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 101
#> 
#> $error
#> [1] 6.647596e-09
#> 
#> $method
#> [1] "nm"
#> 

# Box constraints
optimlib(c(0.5, 0.5), rosenbrock, rosenbrock_gr, lower = 0, upper = 0.8)
#> $par
#> [1] 0.80 0.64
#> 
#> $value
#> [1] 0.04
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 44
#> 
#> $error
#> [1] 8.949664e-09
#> 
#> $method
#> [1] "bfgs"
#> 

# Global optimization; set.seed() makes the result reproducible
set.seed(2861)
optimlib(c(1, 1), function(x) sum(x^2), method = "de",
         lower = -5, upper = 5, control = list(de = list(n_gen = 200)))
#> $par
#> [1] 0 0
#> 
#> $value
#> [1] 0
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 201
#> 
#> $error
#> [1] 2e-08
#> 
#> $method
#> [1] "de"
#> 
```
