#' Minimize an R function with BFGS
#'
#' Shortcut for `optimlib(x0, fn, gr, method = "bfgs")`, kept for
#' compatibility with version 0.0.1. Use [optimlib()] for other methods,
#' bounds and control settings.
#'
#' @param fn R function taking a numeric vector, returning a scalar.
#' @param gr R function taking a numeric vector, returning the gradient
#'   vector.
#' @param x0 Numeric vector of starting values.
#' @return See [optimlib()].
#' @examples
#' rosenbrock <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
#' rosenbrock_gr <- function(x) c(
#'   -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
#'    200 * (x[2] - x[1]^2))
#' optimlib_bfgs(rosenbrock, rosenbrock_gr, c(-1.2, 1))
#' @export
optimlib_bfgs <- function(fn, gr, x0) {
  optimlib(x0, fn, gr, method = "bfgs")
}

#' Minimize an R function with Nelder-Mead
#'
#' Shortcut for `optimlib(x0, fn, method = "nm")`, kept for compatibility
#' with version 0.0.1. Use [optimlib()] for other methods, bounds and
#' control settings.
#'
#' @param fn R function taking a numeric vector, returning a scalar.
#' @param x0 Numeric vector of starting values.
#' @return See [optimlib()].
#' @examples
#' optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))
#' @export
optimlib_nm <- function(fn, x0) {
  optimlib(x0, fn, method = "nm")
}
