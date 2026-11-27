# Minimize an R function with Nelder-Mead

Shortcut for `optimlib(x0, fn, method = "nm")`, kept for compatibility
with version 0.0.1. Use
[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md)
for other methods, bounds and control settings.

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

See
[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md).

## Examples

``` r
optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))
#> $par
#> [1] 3 3
#> 
#> $value
#> [1] 2.481919e-15
#> 
#> $success
#> [1] TRUE
#> 
#> $iterations
#> [1] 66
#> 
#> $error
#> [1] 2.022608e-09
#> 
#> $method
#> [1] "nm"
#> 
```
