# BFGS on the sphere function: minimum at the origin.
res <- optim_sphere_bfgs(c(2, -3, 4))
expect_true(res$success)
expect_equal(res$par, c(0, 0, 0), tolerance = 1e-6)
expect_equal(res$value, 0, tolerance = 1e-10)

# Differential evolution on the Ackley function: global minimum 0 at origin.
res <- optim_ackley_de(c(2, -2), seed = 42L)
expect_true(res$success)
expect_equal(res$par, c(0, 0), tolerance = 1e-4)

# Same seed must reproduce the same solution.
res2 <- optim_ackley_de(c(2, -2), seed = 42L)
expect_identical(res$par, res2$par)

# R-callback BFGS on the Rosenbrock function: minimum at (1, 1).
rosenbrock <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
rosenbrock_gr <- function(x) c(
  -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
   200 * (x[2] - x[1]^2))
res <- optimlib_bfgs(rosenbrock, rosenbrock_gr, c(-1.2, 1))
expect_true(res$success)
expect_equal(res$par, c(1, 1), tolerance = 1e-5)

# R-callback Nelder-Mead, derivative-free.
res <- optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))
expect_true(res$success)
expect_equal(res$par, c(3, 3), tolerance = 1e-4)
