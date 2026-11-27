# Minimize an R function subject to nonlinear inequality constraints

Uses OptimLib's sequential unconstrained minimization technique (SUMT):
a sequence of BFGS minimizations of `fn` plus a quadratic penalty on
violated constraints, with the penalty growing by `sumt$par_eta` (see
[`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md))
each outer iteration.

## Usage

``` r
optimlib_sumt(
  par,
  fn,
  gr = NULL,
  constr,
  constr_jac = NULL,
  ...,
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

  Gradient of `fn`; if `NULL`, approximated by finite differences.

- constr:

  Constraint function, called as `constr(par, ...)` and returning a
  numeric vector. The constraints are `constr(par) <= 0`.

- constr_jac:

  Jacobian of `constr`, called as `constr_jac(par, ...)` and returning a
  `length(constr(par))` x `length(par)` matrix. If `NULL`, approximated
  by finite differences.

- ...:

  Further arguments passed to `fn`, `gr` and `hess`.

- control:

  A list of settings, or the result of
  [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md).

## Value

As for
[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md),
with `method = "sumt"`.

## Examples

``` r
# Minimize (x1 - 2)^2 + (x2 - 2)^2 subject to x1 + x2 <= 2
optimlib_sumt(
  c(0, 0),
  fn = function(x) sum((x - 2)^2),
  gr = function(x) 2 * (x - 2),
  constr = function(x) x[1] + x[2] - 2,
  constr_jac = function(x) matrix(c(1, 1), nrow = 1)
)
#> $par
#> [1] 1 1
#> 
#> $value
#> [1] 2
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 20
#> 
#> $error
#> [1] 0
#> 
#> $method
#> [1] "sumt"
#> 
```
