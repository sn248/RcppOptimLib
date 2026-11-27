# Minimize an R function with BFGS

Shortcut for `optimlib(x0, fn, gr, method = "bfgs")`, kept for
compatibility with version 0.0.1. Use
[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md)
for other methods, bounds and control settings.

## Usage

``` r
optimlib_bfgs(fn, gr, x0)
```

## Arguments

- fn:

  R function taking a numeric vector, returning a scalar.

- gr:

  R function taking a numeric vector, returning the gradient vector.

- x0:

  Numeric vector of starting values.

## Value

See
[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md).

## Examples

``` r
rosenbrock <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(
  -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
   200 * (x[2] - x[1]^2))
optimlib_bfgs(rosenbrock, rosenbrock_gr, c(-1.2, 1))
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
```
