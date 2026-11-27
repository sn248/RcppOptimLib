# Solve a system of nonlinear equations

Finds `par` such that `fn(par) = 0` using Broyden's method, a
quasi-Newton root finder.

## Usage

``` r
optimlib_root(
  par,
  fn,
  jac = NULL,
  ...,
  method = c("broyden", "broyden_df"),
  control = list()
)
```

## Arguments

- par:

  Numeric vector of starting values.

- fn:

  Function called as `fn(par, ...)` and returning a numeric vector of
  the same length as `par`.

- jac:

  Optional Jacobian of `fn`, called as `jac(par, ...)` and returning a
  square matrix. If `NULL`, OptimLib builds its own approximation.

- ...:

  Further arguments passed to `fn` and `jac`.

- method:

  `"broyden"` (Broyden's method) or `"broyden_df"` (derivative-free
  variant of Li and Fukushima, 2000, with a nonmonotone line search).
  Without `jac`, both start from an identity approximation of the
  Jacobian and can diverge from poor starting values; supplying `jac` or
  a better `par` helps. Check `success` and `fn_values`.

- control:

  A list of settings, or the result of
  [`optimlib_control()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_control.md).

## Value

A list with elements `par`, `fn_values` (`fn` at `par`), `success`,
`iterations`, `error` and `method`.

## Examples

``` r
# x^2 + y^2 = 4 and x = y
optimlib_root(c(1, 0.5), function(x) c(x[1]^2 + x[2]^2 - 4, x[1] - x[2]))
#> $par
#> [1] 1.414214 1.414214
#> 
#> $fn_values
#> [1] -8.881784e-16  0.000000e+00
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 18
#> 
#> $error
#> [1] 1.776357e-10
#> 
#> $method
#> [1] "broyden"
#> 
```
