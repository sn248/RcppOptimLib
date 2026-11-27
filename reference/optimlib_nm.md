# Minimize an R function with Nelder-Mead via callbacks

Derivative-free minimization of a plain R function, so no gradient
function is needed. Same callback-overhead caveat as
[`optimlib_bfgs()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_bfgs.md).

## Usage

``` r
optimlib_nm(fn, x0)
```

## Arguments

- fn:

  R function taking a numeric vector, returning a scalar.

- x0:

  Numeric vector of starting values.

## Value

A list with elements `par`, `value`, `iterations` and `success`.

## Examples

``` r
optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))
#> $par
#> [1] 3 3
#> 
#> $value
#> [1] 2.481919e-15
#> 
#> $iterations
#> [1] 66
#> 
#> $success
#> [1] TRUE
#> 
```
