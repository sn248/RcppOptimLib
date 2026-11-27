# Control settings for OptimLib algorithms

Builds a validated list of settings for
[`optimlib()`](https://sn248.github.io/RcppOptimLib/reference/optimlib.md),
[`optimlib_sumt()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_sumt.md)
and
[`optimlib_root()`](https://sn248.github.io/RcppOptimLib/reference/optimlib_root.md).
Unspecified settings take OptimLib's defaults. Algorithm-specific
settings are given as named lists; only the entries you supply are
changed, and unknown names are an error.

## Usage

``` r
optimlib_control(
  iter_max = 2000,
  grad_err_tol = 1e-08,
  rel_sol_change_tol = 1e-14,
  rel_objfn_change_tol = 1e-08,
  print_level = 0,
  conv_failure_switch = 0,
  seed = NULL,
  bfgs = list(),
  lbfgs = list(),
  cg = list(),
  gd = list(),
  nm = list(),
  de = list(),
  pso = list(),
  sumt = list(),
  broyden = list()
)
```

## Arguments

- iter_max:

  Maximum number of iterations (gradient-based methods, Nelder-Mead,
  SUMT outer loop and root finding). Population methods use `n_gen` in
  `de` / `pso` instead.

- grad_err_tol:

  Convergence tolerance on the gradient norm.

- rel_sol_change_tol:

  Convergence tolerance on the relative change in the parameters.

- rel_objfn_change_tol:

  Convergence tolerance on the relative change in the objective value.

- print_level:

  Amount of trace output, from `0` (none) to `4`.

- conv_failure_switch:

  What to do on convergence failure: `0` returns the best guess
  silently, `1` returns it with a message, `2` leaves `par` at its
  starting value and prints the best guess.

- seed:

  Seed for the random number generator used by the population methods
  (`"de"`, `"de_prmm"`, `"pso"`, `"pso_dv"`). If `NULL` (default), a
  seed is drawn from R's RNG, so results are reproducible with
  [`set.seed()`](https://rdrr.io/r/base/Random.html).

- bfgs, lbfgs, cg, gd, nm, de, pso, sumt, broyden:

  Named lists of algorithm-specific settings; see Details.

## Value

A list of class `optimlib_control`.

## Details

The algorithm-specific entries and their defaults are:

- `bfgs`: `wolfe_cons_1 = 1e-3`, `wolfe_cons_2 = 0.9` (line search).

- `lbfgs`: `par_M = 10` (stored correction pairs),
  `wolfe_cons_1 = 1e-3`, `wolfe_cons_2 = 0.9`.

- `cg`: `method = "pr"`, one of `"fr"` (Fletcher-Reeves), `"pr"`
  (Polak-Ribiere+), `"fr_pr"` (hybrid), `"hs"` (Hestenes-Stiefel),
  `"dy"` (Dai-Yuan), `"hz"` (Hager-Zhang); `restart_threshold = 0.1`,
  `use_rel_sol_change_crit = FALSE`, `wolfe_cons_1 = 1e-3`,
  `wolfe_cons_2 = 0.1`.

- `gd`: `method = "basic"`, one of `"basic"`, `"momentum"`, `"nag"`,
  `"adagrad"`, `"rmsprop"`, `"adadelta"`, `"adam"`, `"nadam"`;
  `par_step_size = 0.1`, `step_decay = FALSE`,
  `step_decay_periods = 10`, `step_decay_val = 0.5`,
  `par_momentum = 0.9`, `par_ada_norm_term = 1e-8`, `par_ada_rho = 0.9`,
  `ada_max = FALSE` (AdaMax / NadaMax variants),
  `par_adam_beta_1 = 0.9`, `par_adam_beta_2 = 0.999`,
  `clip_grad = FALSE`, `clip_max_norm = FALSE`, `clip_min_norm = FALSE`,
  `clip_norm_type = 2`, `clip_norm_bound = 5`.

- `nm`: `adaptive_pars = TRUE`, `par_alpha = 1` (reflection),
  `par_beta = 0.5` (contraction), `par_gamma = 2` (expansion),
  `par_delta = 0.5` (shrinkage).

- `de` (also used by `"de_prmm"`): `n_pop = 200`, `n_pop_best = 6`,
  `n_gen = 1000`, `mutation_method = 1` (`1` rand, `2` best),
  `check_freq = Inf`, `par_F = 0.8`, `par_CR = 0.9`, and for `"de_prmm"`
  `pmax = 4`, `max_fn_eval = 1e5`, `par_F_l = 0.1`, `par_F_u = 1`,
  `par_tau_F = 0.1`, `par_tau_CR = 0.1`, `par_d_eps = 0.5`. `"de_prmm"`
  ignores `n_gen`: its budget is set by `max_fn_eval` and `pmax`, and it
  halves the population three times, so it needs
  `n_pop %/% 8 > n_pop_best`; `initial_lb = NULL`, `initial_ub = NULL`
  (range of the initial population; defaults to `par -/+ 0.5`).

- `pso` (also used by `"pso_dv"`): `center_particle = TRUE`,
  `n_pop = 200`, `n_gen = 1000`, `check_freq = Inf`,
  `inertia_method = 1` (`1` linearly decreasing, `2` dampening),
  `par_w = 1`, `par_w_damp = 0.99`, `par_w_min = 0.1`,
  `par_w_max = 0.99`, `velocity_method = 1` (`1` fixed, `2` linear),
  `par_c_cog = 2`, `par_c_soc = 2`, `par_final_c_cog = 0.5`,
  `par_final_c_soc = 2.5`, `initial_lb = NULL`, `initial_ub = NULL`.

- `sumt`: `par_eta = 10` (growth factor of the penalty parameter).

- `broyden`: `par_rho = 0.9`, `par_sigma_1 = 1e-3`,
  `par_sigma_2 = 1e-3`.

See the OptimLib documentation (<https://optimlib.readthedocs.io/>) for
the meaning of each setting.

## Examples

``` r
optimlib_control(iter_max = 500, lbfgs = list(par_M = 20))
#> <optimlib_control>
#>  $ iter_max            : num 500
#>  $ grad_err_tol        : num 1e-08
#>  $ rel_sol_change_tol  : num 1e-14
#>  $ rel_objfn_change_tol: num 1e-08
#>  $ print_level         : int 0
#>  $ conv_failure_switch : int 0
#>  $ seed                : NULL
#>  $ bfgs                :List of 2
#>   ..$ wolfe_cons_1: num 0.001
#>   ..$ wolfe_cons_2: num 0.9
#>  $ lbfgs               :List of 3
#>   ..$ par_M       : num 20
#>   ..$ wolfe_cons_1: num 0.001
#>   ..$ wolfe_cons_2: num 0.9
#>  $ cg                  :List of 5
#>   ..$ method                 : int 2
#>   ..$ restart_threshold      : num 0.1
#>   ..$ use_rel_sol_change_crit: logi FALSE
#>   ..$ wolfe_cons_1           : num 0.001
#>   ..$ wolfe_cons_2           : num 0.1
#>  $ gd                  :List of 16
#>   ..$ method            : int 0
#>   ..$ par_step_size     : num 0.1
#>   ..$ step_decay        : logi FALSE
#>   ..$ step_decay_periods: num 10
#>   ..$ step_decay_val    : num 0.5
#>   ..$ par_momentum      : num 0.9
#>   ..$ par_ada_norm_term : num 1e-08
#>   ..$ par_ada_rho       : num 0.9
#>   ..$ ada_max           : logi FALSE
#>   ..$ par_adam_beta_1   : num 0.9
#>   ..$ par_adam_beta_2   : num 0.999
#>   ..$ clip_grad         : logi FALSE
#>   ..$ clip_max_norm     : logi FALSE
#>   ..$ clip_min_norm     : logi FALSE
#>   ..$ clip_norm_type    : int 2
#>   ..$ clip_norm_bound   : num 5
#>  $ nm                  :List of 5
#>   ..$ adaptive_pars: logi TRUE
#>   ..$ par_alpha    : num 1
#>   ..$ par_beta     : num 0.5
#>   ..$ par_gamma    : num 2
#>   ..$ par_delta    : num 0.5
#>  $ de                  :List of 16
#>   ..$ n_pop          : num 200
#>   ..$ n_pop_best     : num 6
#>   ..$ n_gen          : num 1000
#>   ..$ mutation_method: num 1
#>   ..$ check_freq     : num Inf
#>   ..$ par_F          : num 0.8
#>   ..$ par_CR         : num 0.9
#>   ..$ pmax           : int 4
#>   ..$ max_fn_eval    : num 1e+05
#>   ..$ par_F_l        : num 0.1
#>   ..$ par_F_u        : num 1
#>   ..$ par_tau_F      : num 0.1
#>   ..$ par_tau_CR     : num 0.1
#>   ..$ par_d_eps      : num 0.5
#>   ..$ initial_lb     : NULL
#>   ..$ initial_ub     : NULL
#>  $ pso                 :List of 16
#>   ..$ center_particle: logi TRUE
#>   ..$ n_pop          : num 200
#>   ..$ n_gen          : num 1000
#>   ..$ check_freq     : num Inf
#>   ..$ inertia_method : int 1
#>   ..$ par_w          : num 1
#>   ..$ par_w_damp     : num 0.99
#>   ..$ par_w_min      : num 0.1
#>   ..$ par_w_max      : num 0.99
#>   ..$ velocity_method: int 1
#>   ..$ par_c_cog      : num 2
#>   ..$ par_c_soc      : num 2
#>   ..$ par_final_c_cog: num 0.5
#>   ..$ par_final_c_soc: num 2.5
#>   ..$ initial_lb     : NULL
#>   ..$ initial_ub     : NULL
#>  $ sumt                :List of 1
#>   ..$ par_eta: num 10
#>  $ broyden             :List of 3
#>   ..$ par_rho    : num 0.9
#>   ..$ par_sigma_1: num 0.001
#>   ..$ par_sigma_2: num 0.001
```
