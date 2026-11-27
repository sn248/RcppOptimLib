# Minimize the sphere function with BFGS (C++ objective)

Demonstrates calling `optim::bfgs()` on an objective written entirely in
C++, with an analytic gradient.

## Usage

``` r
optim_sphere_bfgs(x0)
```

## Arguments

- x0:

  Numeric vector of starting values.

## Value

A list with elements `par`, `value`, `iterations` and `success`.

## Examples

``` r
optim_sphere_bfgs(c(2, -3, 4))
#> $par
#> [1] 0.000000e+00 4.336809e-19 0.000000e+00
#> 
#> $value
#> [1] 1.880791e-37
#> 
#> $iterations
#> [1] 1
#> 
#> $success
#> [1] TRUE
#> 
```
