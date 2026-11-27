rosen <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosen_gr <- function(x) {
  c(
    -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
    200 * (x[2] - x[1]^2)
  )
}
rosen_hess <- function(x) {
  matrix(
    c(1200 * x[1]^2 - 400 * x[2] + 2, -400 * x[1], -400 * x[1], 200),
    2
  )
}

# Local methods: analytic and numerical gradients reach (1, 1).
for (m in c("bfgs", "lbfgs", "cg", "newton")) {
  res <- optimlib(c(-1.2, 1), rosen, rosen_gr, method = m, hess = rosen_hess)
  expect_true(res$success, info = m)
  expect_equal(res$par, c(1, 1), tolerance = 1e-5, info = m)
  expect_identical(res$method, m)

  res <- optimlib(c(-1.2, 1), rosen, method = m)
  expect_equal(res$par, c(1, 1), tolerance = 1e-4, info = paste(m, "numeric"))
}

res <- optimlib(c(-1.2, 1), rosen, method = "nm")
expect_true(res$success)
expect_equal(res$par, c(1, 1), tolerance = 1e-4)

res <- optimlib(
  c(-1.2, 1),
  rosen,
  rosen_gr,
  method = "gd",
  control = list(
    iter_max = 1e5,
    gd = list(method = "adam", par_step_size = 0.01)
  )
)
expect_equal(res$par, c(1, 1), tolerance = 1e-4)

# Population methods (small budgets to keep tests fast).
sphere <- function(x) sum((x - 1)^2)
for (m in c("de", "de_prmm", "pso", "pso_dv")) {
  set.seed(3907)
  res <- optimlib(
    c(3, -2),
    sphere,
    method = m,
    lower = -5,
    upper = 5,
    control = list(
      de = list(n_gen = 300, n_pop = 64, max_fn_eval = 2e4),
      pso = list(n_gen = 300, n_pop = 50)
    )
  )
  expect_equal(res$par, c(1, 1), tolerance = 1e-3, info = m)
}
expect_error(
  optimlib(
    c(3, -2),
    sphere,
    method = "de_prmm",
    control = list(de = list(n_pop = 50))
  ),
  "reduces to 6"
)

# Population methods are reproducible under set.seed() ...
run_pso <- function() {
  optimlib(
    c(2, 2),
    rosen,
    method = "pso",
    control = list(pso = list(n_gen = 30, n_pop = 20))
  )$par
}
set.seed(611)
a <- run_pso()
set.seed(611)
b <- run_pso()
expect_identical(a, b)
# ... and an explicit seed overrides R's RNG.
ctrl <- list(seed = 99, pso = list(n_gen = 30, n_pop = 20))
expect_identical(
  optimlib(c(2, 2), rosen, method = "pso", control = ctrl)$par,
  optimlib(c(2, 2), rosen, method = "pso", control = ctrl)$par
)
# Deterministic methods don't consume R's RNG.
set.seed(20)
before <- .Random.seed
optimlib(c(-1.2, 1), rosen, rosen_gr)
expect_identical(.Random.seed, before)

# Box constraints.
res <- optimlib(
  c(0.5, 0.5),
  rosen,
  rosen_gr,
  method = "lbfgs",
  lower = 0,
  upper = 0.8
)
expect_equal(res$par, c(0.8, 0.64), tolerance = 1e-5)

# `...` is passed to fn and gr.
res <- optimlib(0, function(x, a) (x - a)^2, function(x, a) 2 * (x - a), a = 7)
expect_equal(res$par, 7, tolerance = 1e-6)

# Callback receives a plain numeric vector.
optimlib(
  c(1, 2),
  function(x) {
    expect_null(dim(x))
    sum(x^2)
  },
  method = "nm",
  control = list(iter_max = 5)
)

# Errors in R callbacks propagate.
expect_error(optimlib(1, function(x) stop("boom")), "boom")
expect_error(
  optimlib(1, function(x) if (x[1] == 1) 1 else stop("late")),
  "late"
)
expect_error(optimlib(1:2, function(x) x), "single number")
expect_error(optimlib(1, function(x) x^2, function(x) c(1, 2)), "length 1")

# Argument and control validation.
expect_error(
  optimlib(1, function(x) x^2, method = "newton", lower = 0),
  "does not support bounds"
)
expect_error(optimlib(0, function(x) x^2, lower = 0), "strictly inside")
expect_error(
  optimlib(1, function(x) x^2, control = list(itr_max = 5)),
  "Unknown `control`"
)
expect_error(optimlib_control(cg = list(metod = 1)), "Unknown `cg`")
expect_error(optimlib_control(gd = list(method = "sgd")), "gd\\$method")
expect_error(optimlib_control(iter_max = -1), "iter_max")
expect_identical(optimlib_control(cg = list(method = "hz"))$cg$method, 6L)
expect_inherits(optimlib_control(), "optimlib_control")

# SUMT: min (x - 2)^2 + (y - 2)^2 subject to x + y <= 2  ->  (1, 1).
res <- optimlib_sumt(
  c(0, 0),
  function(x) sum((x - 2)^2),
  function(x) 2 * (x - 2),
  constr = function(x) x[1] + x[2] - 2,
  constr_jac = function(x) matrix(c(1, 1), nrow = 1)
)
expect_true(res$success)
expect_equal(res$par, c(1, 1), tolerance = 1e-4)
res <- optimlib_sumt(c(0, 0), function(x) sum((x - 2)^2), constr = function(x) {
  x[1] + x[2] - 2
})
expect_equal(res$par, c(1, 1), tolerance = 1e-4)

# SUMT, nonlinear constraint: nearest point to (2, 2) in the unit disc.
res <- optimlib_sumt(
  c(0, 0),
  function(x) sum((x - 2)^2),
  constr = function(x) sum(x^2) - 1
)
expect_equal(res$par, rep(1 / sqrt(2), 2), tolerance = 1e-4)

# Root finding: x^2 + y^2 = 4, x = y.
f <- function(x) c(x[1]^2 + x[2]^2 - 4, x[1] - x[2])
j <- function(x) matrix(c(2 * x[1], 1, 2 * x[2], -1), 2)
for (m in c("broyden", "broyden_df")) {
  res <- optimlib_root(c(1.2, 1.3), f, method = m)
  expect_true(res$success, info = m)
  expect_equal(res$par, rep(sqrt(2), 2), tolerance = 1e-6, info = m)
  res <- optimlib_root(c(1, 0.5), f, jac = j, method = m)
  expect_equal(res$par, rep(sqrt(2), 2), tolerance = 1e-6, info = m)
}
