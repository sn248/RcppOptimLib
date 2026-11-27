# Minimize an R function with BFGS via callbacks

The objective and gradient are plain R functions, called from C++ on
every evaluation. Convenient, but the callback overhead makes this
slower than a C++ objective; for performance-critical work write the
objective in C++ against the OptimLib headers (see the vignette).

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

A list with elements `par`, `value`, `iterations` and `success`.

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
#> $iterations
#> [1] 31
#> 
#> $success
#> [1] TRUE
#> 
```
