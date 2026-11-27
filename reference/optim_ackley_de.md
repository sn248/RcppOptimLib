# Minimize the Ackley function with Differential Evolution (C++ objective)

Demonstrates a derivative-free global optimizer on a multimodal
function. Box bounds and the RNG seed are set through
`optim::algo_settings_t`.

## Usage

``` r
optim_ackley_de(x0, seed = 1L)
```

## Arguments

- x0:

  Numeric vector of starting values.

- seed:

  Integer seed for OptimLib's internal RNG, for reproducibility.

## Value

A list with elements `par`, `value`, `iterations` and `success`.

## Examples

``` r
optim_ackley_de(c(2, -2), seed = 42L)
#> $par
#> [1]  0.000000e+00 -2.775558e-16
#> 
#> $value
#> [1] 4.440892e-16
#> 
#> $iterations
#> [1] 1001
#> 
#> $success
#> [1] TRUE
#> 
```
