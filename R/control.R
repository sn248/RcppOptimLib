#' Control settings for OptimLib algorithms
#'
#' Builds a validated list of settings for [optimlib()], [optimlib_sumt()]
#' and [optimlib_root()]. Unspecified settings take OptimLib's defaults.
#' Algorithm-specific settings are given as named lists; only the entries you
#' supply are changed, and unknown names are an error.
#'
#' @param iter_max Maximum number of iterations (gradient-based methods,
#'   Nelder-Mead, SUMT outer loop and root finding). Population methods use
#'   `n_gen` in `de` / `pso` instead.
#' @param grad_err_tol Convergence tolerance on the gradient norm.
#' @param rel_sol_change_tol Convergence tolerance on the relative change in
#'   the parameters.
#' @param rel_objfn_change_tol Convergence tolerance on the relative change in
#'   the objective value.
#' @param print_level Amount of trace output, from `0` (none) to `4`.
#' @param conv_failure_switch What to do on convergence failure: `0` returns
#'   the best guess silently, `1` returns it with a message, `2` leaves `par`
#'   at its starting value and prints the best guess.
#' @param seed Seed for the random number generator used by the population
#'   methods (`"de"`, `"de_prmm"`, `"pso"`, `"pso_dv"`). If `NULL` (default), a
#'   seed is drawn from R's RNG, so results are reproducible with
#'   [set.seed()].
#' @param bfgs,lbfgs,cg,gd,nm,de,pso,sumt,broyden Named lists of
#'   algorithm-specific settings; see Details.
#'
#' @details
#' The algorithm-specific entries and their defaults are:
#'
#' * `bfgs`: `wolfe_cons_1 = 1e-3`, `wolfe_cons_2 = 0.9` (line search).
#' * `lbfgs`: `par_M = 10` (stored correction pairs), `wolfe_cons_1 = 1e-3`,
#'   `wolfe_cons_2 = 0.9`.
#' * `cg`: `method = "pr"`, one of `"fr"` (Fletcher-Reeves), `"pr"`
#'   (Polak-Ribiere+), `"fr_pr"` (hybrid), `"hs"` (Hestenes-Stiefel), `"dy"`
#'   (Dai-Yuan), `"hz"` (Hager-Zhang); `restart_threshold = 0.1`,
#'   `use_rel_sol_change_crit = FALSE`, `wolfe_cons_1 = 1e-3`,
#'   `wolfe_cons_2 = 0.1`.
#' * `gd`: `method = "basic"`, one of `"basic"`, `"momentum"`, `"nag"`,
#'   `"adagrad"`, `"rmsprop"`, `"adadelta"`, `"adam"`, `"nadam"`;
#'   `par_step_size = 0.1`, `step_decay = FALSE`, `step_decay_periods = 10`,
#'   `step_decay_val = 0.5`, `par_momentum = 0.9`, `par_ada_norm_term = 1e-8`,
#'   `par_ada_rho = 0.9`, `ada_max = FALSE` (AdaMax / NadaMax variants),
#'   `par_adam_beta_1 = 0.9`, `par_adam_beta_2 = 0.999`, `clip_grad = FALSE`,
#'   `clip_max_norm = FALSE`, `clip_min_norm = FALSE`, `clip_norm_type = 2`,
#'   `clip_norm_bound = 5`.
#' * `nm`: `adaptive_pars = TRUE`, `par_alpha = 1` (reflection),
#'   `par_beta = 0.5` (contraction), `par_gamma = 2` (expansion),
#'   `par_delta = 0.5` (shrinkage).
#' * `de` (also used by `"de_prmm"`): `n_pop = 200`, `n_pop_best = 6`,
#'   `n_gen = 1000`, `mutation_method = 1` (`1` rand, `2` best),
#'   `check_freq = Inf`, `par_F = 0.8`, `par_CR = 0.9`, and for `"de_prmm"`
#'   `pmax = 4`, `max_fn_eval = 1e5`, `par_F_l = 0.1`, `par_F_u = 1`,
#'   `par_tau_F = 0.1`, `par_tau_CR = 0.1`, `par_d_eps = 0.5`. `"de_prmm"`
#'   ignores `n_gen`: its budget is set by `max_fn_eval` and `pmax`, and it
#'   halves the population three times, so it needs
#'   `n_pop %/% 8 > n_pop_best`;
#'   `initial_lb = NULL`, `initial_ub = NULL` (range of the initial
#'   population; defaults to `par -/+ 0.5`).
#' * `pso` (also used by `"pso_dv"`): `center_particle = TRUE`,
#'   `n_pop = 200`, `n_gen = 1000`, `check_freq = Inf`,
#'   `inertia_method = 1` (`1` linearly decreasing, `2` dampening),
#'   `par_w = 1`, `par_w_damp = 0.99`, `par_w_min = 0.1`, `par_w_max = 0.99`,
#'   `velocity_method = 1` (`1` fixed, `2` linear), `par_c_cog = 2`,
#'   `par_c_soc = 2`, `par_final_c_cog = 0.5`, `par_final_c_soc = 2.5`,
#'   `initial_lb = NULL`, `initial_ub = NULL`.
#' * `sumt`: `par_eta = 10` (growth factor of the penalty parameter).
#' * `broyden`: `par_rho = 0.9`, `par_sigma_1 = 1e-3`, `par_sigma_2 = 1e-3`.
#'
#' See the OptimLib documentation (<https://optimlib.readthedocs.io/>) for the
#' meaning of each setting.
#'
#' @return A list of class `optimlib_control`.
#' @examples
#' optimlib_control(iter_max = 500, lbfgs = list(par_M = 20))
#' @export
optimlib_control <- function(
  iter_max = 2000,
  grad_err_tol = 1e-8,
  rel_sol_change_tol = 1e-14,
  rel_objfn_change_tol = 1e-8,
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
) {
  check_count(iter_max, "iter_max")
  check_number(grad_err_tol, "grad_err_tol", min = 0)
  check_number(rel_sol_change_tol, "rel_sol_change_tol", min = 0)
  check_number(rel_objfn_change_tol, "rel_objfn_change_tol", min = 0)
  check_choice_int(print_level, "print_level", 0:4)
  check_choice_int(conv_failure_switch, "conv_failure_switch", 0:2)
  if (!is.null(seed)) {
    check_count(seed, "seed", min = 0)
  }

  ctrl <- list(
    iter_max = iter_max,
    grad_err_tol = grad_err_tol,
    rel_sol_change_tol = rel_sol_change_tol,
    rel_objfn_change_tol = rel_objfn_change_tol,
    print_level = as.integer(print_level),
    conv_failure_switch = as.integer(conv_failure_switch),
    seed = seed
  )

  user <- list(
    bfgs = bfgs,
    lbfgs = lbfgs,
    cg = cg,
    gd = gd,
    nm = nm,
    de = de,
    pso = pso,
    sumt = sumt,
    broyden = broyden
  )
  for (algo in names(user)) {
    ctrl[[algo]] <- merge_algo_settings(algo, user[[algo]])
  }

  structure(ctrl, class = "optimlib_control")
}

#' @export
print.optimlib_control <- function(x, ...) {
  cat("<optimlib_control>\n")
  utils::str(unclass(x), give.attr = FALSE, no.list = TRUE)
  invisible(x)
}

cg_methods <- c(
  "fr" = 1L,
  "pr" = 2L,
  "fr_pr" = 3L,
  "hs" = 4L,
  "dy" = 5L,
  "hz" = 6L
)
gd_methods <- c(
  "basic" = 0L,
  "momentum" = 1L,
  "nag" = 2L,
  "adagrad" = 3L,
  "rmsprop" = 4L,
  "adadelta" = 5L,
  "adam" = 6L,
  "nadam" = 7L
)

algo_defaults <- function() {
  list(
    bfgs = list(wolfe_cons_1 = 1e-3, wolfe_cons_2 = 0.9),
    lbfgs = list(par_M = 10, wolfe_cons_1 = 1e-3, wolfe_cons_2 = 0.9),
    cg = list(
      method = "pr",
      restart_threshold = 0.1,
      use_rel_sol_change_crit = FALSE,
      wolfe_cons_1 = 1e-3,
      wolfe_cons_2 = 0.1
    ),
    gd = list(
      method = "basic",
      par_step_size = 0.1,
      step_decay = FALSE,
      step_decay_periods = 10,
      step_decay_val = 0.5,
      par_momentum = 0.9,
      par_ada_norm_term = 1e-8,
      par_ada_rho = 0.9,
      ada_max = FALSE,
      par_adam_beta_1 = 0.9,
      par_adam_beta_2 = 0.999,
      clip_grad = FALSE,
      clip_max_norm = FALSE,
      clip_min_norm = FALSE,
      clip_norm_type = 2L,
      clip_norm_bound = 5
    ),
    nm = list(
      adaptive_pars = TRUE,
      par_alpha = 1,
      par_beta = 0.5,
      par_gamma = 2,
      par_delta = 0.5
    ),
    de = list(
      n_pop = 200,
      n_pop_best = 6,
      n_gen = 1000,
      mutation_method = 1,
      check_freq = Inf,
      par_F = 0.8,
      par_CR = 0.9,
      pmax = 4L,
      max_fn_eval = 1e5,
      par_F_l = 0.1,
      par_F_u = 1,
      par_tau_F = 0.1,
      par_tau_CR = 0.1,
      par_d_eps = 0.5,
      initial_lb = NULL,
      initial_ub = NULL
    ),
    pso = list(
      center_particle = TRUE,
      n_pop = 200,
      n_gen = 1000,
      check_freq = Inf,
      inertia_method = 1L,
      par_w = 1,
      par_w_damp = 0.99,
      par_w_min = 0.1,
      par_w_max = 0.99,
      velocity_method = 1L,
      par_c_cog = 2,
      par_c_soc = 2,
      par_final_c_cog = 0.5,
      par_final_c_soc = 2.5,
      initial_lb = NULL,
      initial_ub = NULL
    ),
    sumt = list(par_eta = 10),
    broyden = list(par_rho = 0.9, par_sigma_1 = 1e-3, par_sigma_2 = 1e-3)
  )
}

merge_algo_settings <- function(algo, user) {
  if (!is.list(user)) {
    stop(sprintf("`%s` must be a list.", algo), call. = FALSE)
  }
  out <- algo_defaults()[[algo]]
  if (length(user) == 0) {
    return(finalize_algo_settings(algo, out))
  }
  if (is.null(names(user)) || any(names(user) == "")) {
    stop(sprintf("All entries of `%s` must be named.", algo), call. = FALSE)
  }
  unknown <- setdiff(names(user), names(out))
  if (length(unknown) > 0) {
    stop(
      sprintf(
        "Unknown `%s` setting(s): %s.\nValid settings: %s.",
        algo,
        paste0("`", unknown, "`", collapse = ", "),
        paste(names(out), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  for (nm in names(user)) {
    # `[<-` with list(NULL) keeps NULL entries instead of dropping them
    out[nm] <- list(user[[nm]])
  }
  finalize_algo_settings(algo, out)
}

finalize_algo_settings <- function(algo, s) {
  label <- function(nm) paste0(algo, "$", nm)
  for (nm in names(s)) {
    val <- s[[nm]]
    default <- algo_defaults()[[algo]][[nm]]
    if (nm == "method" || nm %in% c("initial_lb", "initial_ub")) {
      next
    }
    if (is.logical(default)) {
      if (!is.logical(val) || length(val) != 1 || is.na(val)) {
        stop(sprintf("`%s` must be TRUE or FALSE.", label(nm)), call. = FALSE)
      }
    } else if (is.numeric(default)) {
      check_number(val, label(nm), allow_inf = is.infinite(default))
    }
  }

  if (algo == "cg") {
    s$method <- match_method(s$method, cg_methods, label("method"))
  }
  if (algo == "gd") {
    s$method <- match_method(s$method, gd_methods, label("method"))
  }
  for (nm in intersect(c("initial_lb", "initial_ub"), names(s))) {
    if (!is.null(s[[nm]])) {
      if (!is.numeric(s[[nm]]) || anyNA(s[[nm]]) || any(!is.finite(s[[nm]]))) {
        stop(
          sprintf("`%s` must be NULL or a finite numeric vector.", label(nm)),
          call. = FALSE
        )
      }
      s[[nm]] <- as.double(s[[nm]])
    }
  }
  s
}

match_method <- function(x, table, what) {
  if (is.character(x) && length(x) == 1 && x %in% names(table)) {
    return(table[[x]])
  }
  if (is.numeric(x) && length(x) == 1 && x %in% table) {
    return(as.integer(x))
  }
  stop(
    sprintf(
      "`%s` must be one of %s.",
      what,
      paste0("\"", names(table), "\"", collapse = ", ")
    ),
    call. = FALSE
  )
}

as_optimlib_control <- function(control) {
  if (inherits(control, "optimlib_control")) {
    return(control)
  }
  if (!is.list(control)) {
    stop(
      "`control` must be a list or the result of `optimlib_control()`.",
      call. = FALSE
    )
  }
  if (
    length(control) > 0 &&
      (is.null(names(control)) || any(names(control) == ""))
  ) {
    stop("All entries of `control` must be named.", call. = FALSE)
  }
  unknown <- setdiff(names(control), names(formals(optimlib_control)))
  if (length(unknown) > 0) {
    stop(
      sprintf(
        "Unknown `control` setting(s): %s. See `?optimlib_control`.",
        paste0("`", unknown, "`", collapse = ", ")
      ),
      call. = FALSE
    )
  }
  do.call(optimlib_control, control)
}

check_number <- function(x, what, min = -Inf, allow_inf = FALSE) {
  ok <- is.numeric(x) &&
    length(x) == 1 &&
    !is.na(x) &&
    (allow_inf || is.finite(x)) &&
    x >= min
  if (!ok) {
    stop(
      sprintf(
        "`%s` must be a single %snumber%s.",
        what,
        if (allow_inf) "" else "finite ",
        if (is.finite(min)) sprintf(" >= %s", min) else ""
      ),
      call. = FALSE
    )
  }
  invisible(x)
}

check_count <- function(x, what, min = 1) {
  ok <- is.numeric(x) &&
    length(x) == 1 &&
    !is.na(x) &&
    is.finite(x) &&
    x >= min &&
    x == round(x)
  if (!ok) {
    stop(
      sprintf("`%s` must be a single whole number >= %s.", what, min),
      call. = FALSE
    )
  }
  invisible(x)
}

check_choice_int <- function(x, what, choices) {
  if (!(is.numeric(x) && length(x) == 1 && x %in% choices)) {
    stop(
      sprintf("`%s` must be one of %s.", what, paste(choices, collapse = ", ")),
      call. = FALSE
    )
  }
  invisible(x)
}
