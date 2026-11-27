optimlib_methods <- c(
  "bfgs",
  "lbfgs",
  "cg",
  "gd",
  "newton",
  "nm",
  "de",
  "de_prmm",
  "pso",
  "pso_dv"
)
gradient_methods <- c("bfgs", "lbfgs", "cg", "gd", "newton")
stochastic_methods <- c("de", "de_prmm", "pso", "pso_dv")

#' Minimize an R function with OptimLib
#'
#' A general interface to OptimLib's unconstrained and box-constrained
#' minimizers, modelled on [stats::optim()]. The objective (and gradient /
#' Hessian, if supplied) are plain R functions called from C++.
#'
#' @param par Numeric vector of starting values.
#' @param fn Objective function to minimize. Called as `fn(par, ...)` and must
#'   return a single number.
#' @param gr Gradient of `fn`, called as `gr(par, ...)` and returning a
#'   numeric vector of length `length(par)`. If `NULL`, gradient-based methods
#'   use central finite differences. Ignored by derivative-free methods.
#' @param ... Further arguments passed to `fn`, `gr` and `hess`.
#' @param method The algorithm:
#'   * `"bfgs"`: BFGS quasi-Newton.
#'   * `"lbfgs"`: limited-memory BFGS, for many parameters.
#'   * `"cg"`: nonlinear conjugate gradient.
#'   * `"gd"`: gradient descent, including momentum, Nesterov, AdaGrad,
#'     RMSProp, AdaDelta, Adam and Nadam variants (see `gd$method` in
#'     [optimlib_control()]).
#'   * `"newton"`: Newton's method; uses `hess`. Does not support bounds.
#'   * `"nm"`: Nelder-Mead (derivative-free).
#'   * `"de"`, `"de_prmm"`: differential evolution, and its variant with
#'     population reduction and multiple mutation strategies
#'     (derivative-free, global).
#'   * `"pso"`, `"pso_dv"`: particle swarm optimization, and its
#'     differentially perturbed velocity variant (derivative-free, global).
#' @param lower,upper Bounds on the parameters, recycled to `length(par)`.
#'   Use `-Inf` / `Inf` for unbounded parameters. OptimLib handles bounds by
#'   transforming the parameters, so `par` must lie strictly inside them.
#' @param hess Hessian of `fn` for `method = "newton"`, called as
#'   `hess(par, ...)` and returning a `length(par)` x `length(par)` matrix. If
#'   `NULL`, it is approximated by finite differences of the gradient.
#' @param control A list of settings, or the result of [optimlib_control()].
#'
#' @return A list with elements:
#'   * `par`: the best parameter values found.
#'   * `value`: `fn` evaluated at `par`.
#'   * `success`: `TRUE` if OptimLib reports convergence. For the population
#'     methods this is only meaningful when `check_freq` (in `de` / `pso` of
#'     [optimlib_control()]) is finite: with the default `check_freq = Inf`
#'     no convergence test is run, and OptimLib reports `TRUE` for `"de"` but
#'     `FALSE` for `"de_prmm"`, `"pso"` and `"pso_dv"` after `n_gen`
#'     generations. Judge those results by `value`.
#'   * `iterations`: number of iterations (generations for population
#'     methods).
#'   * `error`: the final value of the convergence criterion.
#'   * `method`: the method used.
#'
#' @seealso [optimlib_control()], [optimlib_sumt()] for nonlinear inequality
#'   constraints, [optimlib_root()] for systems of equations.
#' @examples
#' rosenbrock <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
#' rosenbrock_gr <- function(x) c(
#'   -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
#'    200 * (x[2] - x[1]^2))
#'
#' optimlib(c(-1.2, 1), rosenbrock, rosenbrock_gr)
#' optimlib(c(-1.2, 1), rosenbrock, rosenbrock_gr, method = "lbfgs")
#' optimlib(c(-1.2, 1), rosenbrock, method = "nm")
#'
#' # Box constraints
#' optimlib(c(0.5, 0.5), rosenbrock, rosenbrock_gr, lower = 0, upper = 0.8)
#'
#' # Global optimization; set.seed() makes the result reproducible
#' set.seed(2861)
#' optimlib(c(1, 1), function(x) sum(x^2), method = "de",
#'          lower = -5, upper = 5, control = list(de = list(n_gen = 200)))
#' @export
optimlib <- function(
  par,
  fn,
  gr = NULL,
  ...,
  method = c(
    "bfgs",
    "lbfgs",
    "cg",
    "gd",
    "newton",
    "nm",
    "de",
    "de_prmm",
    "pso",
    "pso_dv"
  ),
  lower = -Inf,
  upper = Inf,
  hess = NULL,
  control = list()
) {
  method <- match.arg(method)
  check_par(par)
  fn1 <- wrap_fn(fn, "fn", ...)
  gr1 <- if (!is.null(gr)) wrap_fn(gr, "gr", ...)
  hess1 <- if (!is.null(hess)) wrap_fn(hess, "hess", ...)
  control <- as_optimlib_control(control)
  check_objective_at(fn1, as.double(par))

  if (method %in% gradient_methods && is.null(gr1)) {
    gr1 <- numerical_gradient(fn1)
  }
  if (!method %in% gradient_methods) {
    gr1 <- NULL
  }
  if (method == "newton") {
    hess1 <- hess1 %||% numerical_hessian(gr1)
  }

  bounds <- resolve_bounds(par, lower, upper)
  if (method == "newton" && length(bounds$lower) > 0) {
    stop("`method = \"newton\"` does not support bounds.", call. = FALSE)
  }

  check_population(method, control)
  control$seed <- resolve_seed(control$seed, method %in% stochastic_methods)

  res <- .optimlib_min(
    method,
    as.double(par),
    fn1,
    gr1,
    hess1,
    bounds$lower,
    bounds$upper,
    control
  )
  res$method <- method
  res
}

#' Minimize an R function subject to nonlinear inequality constraints
#'
#' Uses OptimLib's sequential unconstrained minimization technique (SUMT):
#' a sequence of BFGS minimizations of `fn` plus a quadratic penalty on
#' violated constraints, with the penalty growing by `sumt$par_eta` (see
#' [optimlib_control()]) each outer iteration.
#'
#' @inheritParams optimlib
#' @param gr Gradient of `fn`; if `NULL`, approximated by finite differences.
#' @param constr Constraint function, called as `constr(par, ...)` and
#'   returning a numeric vector. The constraints are `constr(par) <= 0`.
#' @param constr_jac Jacobian of `constr`, called as `constr_jac(par, ...)`
#'   and returning a `length(constr(par))` x `length(par)` matrix. If `NULL`,
#'   approximated by finite differences.
#'
#' @return As for [optimlib()], with `method = "sumt"`.
#' @examples
#' # Minimize (x1 - 2)^2 + (x2 - 2)^2 subject to x1 + x2 <= 2
#' optimlib_sumt(
#'   c(0, 0),
#'   fn = function(x) sum((x - 2)^2),
#'   gr = function(x) 2 * (x - 2),
#'   constr = function(x) x[1] + x[2] - 2,
#'   constr_jac = function(x) matrix(c(1, 1), nrow = 1)
#' )
#' @export
optimlib_sumt <- function(
  par,
  fn,
  gr = NULL,
  constr,
  constr_jac = NULL,
  ...,
  control = list()
) {
  check_par(par)
  fn1 <- wrap_fn(fn, "fn", ...)
  gr1 <- if (is.null(gr)) numerical_gradient(fn1) else wrap_fn(gr, "gr", ...)
  constr1 <- wrap_fn(constr, "constr", ...)
  constr_jac1 <- if (is.null(constr_jac)) {
    numerical_jacobian(constr1)
  } else {
    wrap_fn(constr_jac, "constr_jac", ...)
  }
  control <- as_optimlib_control(control)
  control$seed <- resolve_seed(control$seed, FALSE)
  check_objective_at(fn1, as.double(par))

  c0 <- constr1(as.double(par))
  if (!is.numeric(c0) || length(c0) < 1) {
    stop("`constr` must return a numeric vector of length >= 1.", call. = FALSE)
  }
  n_constr <- length(c0)

  res <- .optimlib_sumt(
    as.double(par),
    fn1,
    gr1,
    constr1,
    constr_jac1,
    n_constr,
    control
  )
  res$method <- "sumt"
  res
}

#' Solve a system of nonlinear equations
#'
#' Finds `par` such that `fn(par) = 0` using Broyden's method, a
#' quasi-Newton root finder.
#'
#' @param par Numeric vector of starting values.
#' @param fn Function called as `fn(par, ...)` and returning a numeric vector
#'   of the same length as `par`.
#' @param jac Optional Jacobian of `fn`, called as `jac(par, ...)` and
#'   returning a square matrix. If `NULL`, OptimLib builds its own
#'   approximation.
#' @param ... Further arguments passed to `fn` and `jac`.
#' @param method `"broyden"` (Broyden's method) or `"broyden_df"`
#'   (derivative-free variant of Li and Fukushima, 2000, with a nonmonotone
#'   line search). Without `jac`, both start from an identity approximation
#'   of the Jacobian and can diverge from poor starting values; supplying
#'   `jac` or a better `par` helps. Check `success` and `fn_values`.
#' @param control A list of settings, or the result of [optimlib_control()].
#'
#' @return A list with elements `par`, `fn_values` (`fn` at `par`),
#'   `success`, `iterations`, `error` and `method`.
#' @examples
#' # x^2 + y^2 = 4 and x = y
#' optimlib_root(c(1, 0.5), function(x) c(x[1]^2 + x[2]^2 - 4, x[1] - x[2]))
#' @export
optimlib_root <- function(
  par,
  fn,
  jac = NULL,
  ...,
  method = c("broyden", "broyden_df"),
  control = list()
) {
  method <- match.arg(method)
  check_par(par)
  fn1 <- wrap_fn(fn, "fn", ...)
  jac1 <- if (!is.null(jac)) wrap_fn(jac, "jac", ...)
  control <- as_optimlib_control(control)
  control$seed <- resolve_seed(control$seed, FALSE)

  res <- .optimlib_root(method, as.double(par), fn1, jac1, control)
  res$method <- method
  res
}

# Helpers ---------------------------------------------------------------------

check_objective_at <- function(fn, par) {
  val <- fn(par)
  if (!is.numeric(val) || length(val) != 1) {
    stop(
      sprintf(
        "`fn` must return a single number; it returned %s of length %d.",
        class(val)[1],
        length(val)
      ),
      call. = FALSE
    )
  }
  if (!is.finite(val)) {
    stop("`fn` is not finite at the starting values `par`.", call. = FALSE)
  }
  invisible(val)
}

# OptimLib indexes rows [0, n_pop - n_pop_best) with unsigned arithmetic, so
# these constraints prevent out-of-bounds access rather than bad results.
check_population <- function(method, control) {
  de <- control$de
  if (method == "de" && de$n_pop <= max(de$n_pop_best, 3)) {
    stop(
      "`de$n_pop` must be greater than `de$n_pop_best` and at least 4.",
      call. = FALSE
    )
  }
  if (method == "de_prmm") {
    # de_prmm halves the population three times
    final_pop <- de$n_pop %/% 2 %/% 2 %/% 2
    if (final_pop <= max(de$n_pop_best, 3)) {
      stop(
        sprintf(
          paste0(
            "For `method = \"de_prmm\"`, `de$n_pop` %%/%% 8 must exceed ",
            "`de$n_pop_best` (and 3); `n_pop = %d` reduces to %d."
          ),
          as.integer(de$n_pop),
          as.integer(final_pop)
        ),
        call. = FALSE
      )
    }
  }
  pso <- control$pso
  if (method %in% c("pso", "pso_dv") && pso$n_pop < 4) {
    stop("`pso$n_pop` must be at least 4.", call. = FALSE)
  }
  invisible()
}

check_par <- function(par) {
  if (
    !is.numeric(par) || length(par) == 0 || anyNA(par) || any(!is.finite(par))
  ) {
    stop(
      "`par` must be a non-empty numeric vector of finite values.",
      call. = FALSE
    )
  }
  invisible(par)
}

wrap_fn <- function(f, what, ...) {
  if (!is.function(f)) {
    stop(sprintf("`%s` must be a function.", what), call. = FALSE)
  }
  dots <- list(...)
  if (length(dots) == 0) {
    return(f)
  }
  function(x) do.call(f, c(list(x), dots))
}

resolve_bounds <- function(par, lower, upper) {
  n <- length(par)
  if (
    !is.numeric(lower) || !is.numeric(upper) || anyNA(lower) || anyNA(upper)
  ) {
    stop(
      "`lower` and `upper` must be numeric without missing values.",
      call. = FALSE
    )
  }
  if (!length(lower) %in% c(1, n) || !length(upper) %in% c(1, n)) {
    stop(
      "`lower` and `upper` must have length 1 or `length(par)`.",
      call. = FALSE
    )
  }
  lower <- rep_len(as.double(lower), n)
  upper <- rep_len(as.double(upper), n)
  if (
    all(is.infinite(lower) & lower < 0) &&
      all(is.infinite(upper) & upper > 0)
  ) {
    return(list(lower = double(), upper = double()))
  }
  if (any(lower >= upper)) {
    stop("`lower` must be strictly less than `upper`.", call. = FALSE)
  }
  if (any(par <= lower | par >= upper)) {
    stop("`par` must lie strictly inside `lower` and `upper`.", call. = FALSE)
  }
  list(lower = lower, upper = upper)
}

resolve_seed <- function(seed, stochastic) {
  if (!is.null(seed)) {
    return(as.double(seed))
  }
  # Only consume R's RNG for methods that use randomness.
  if (stochastic) as.double(sample.int(.Machine$integer.max, 1L)) else 0
}

fd_step <- function(x) .Machine$double.eps^(1 / 3) * pmax(abs(x), 1)

numerical_gradient <- function(f) {
  function(x) {
    h <- fd_step(x)
    vapply(
      seq_along(x),
      function(i) {
        e <- numeric(length(x))
        e[i] <- h[i]
        (f(x + e) - f(x - e)) / (2 * h[i])
      },
      numeric(1)
    )
  }
}

numerical_jacobian <- function(f) {
  function(x) {
    h <- fd_step(x)
    cols <- lapply(seq_along(x), function(i) {
      e <- numeric(length(x))
      e[i] <- h[i]
      (f(x + e) - f(x - e)) / (2 * h[i])
    })
    matrix(unlist(cols), ncol = length(x))
  }
}

numerical_hessian <- function(gr) {
  jac <- numerical_jacobian(gr)
  function(x) {
    h <- jac(x)
    (h + t(h)) / 2
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x
