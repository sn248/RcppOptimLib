// Demonstration functions for RcppOptimLib.
//
// Two kinds of use are shown:
//   1. Pure C++ objectives (optim_sphere_bfgs, optim_ackley_de) — the fast
//      path, and the model for client packages using LinkingTo.
//   2. R-function callbacks (optimlib_bfgs, optimlib_nm) — convenient but
//      each objective evaluation crosses the R/C++ boundary.

#include <RcppOptimLib.h>

// [[Rcpp::depends(RcppArmadillo)]]

namespace {

// f(x) = sum(x^2), gradient 2x — minimum at the origin.
double sphere_fn(const arma::vec& x, arma::vec* grad_out, void*)
{
    if (grad_out) {
        *grad_out = 2.0 * x;
    }
    return arma::dot(x, x);
}

// Ackley function: many local minima, global minimum 0 at the origin.
double ackley_fn(const arma::vec& x, arma::vec*, void*)
{
    const double a = 20.0, b = 0.2, c = 2.0 * arma::datum::pi;
    const double n = static_cast<double>(x.n_elem);
    return -a * std::exp(-b * std::sqrt(arma::dot(x, x) / n))
           - std::exp(arma::sum(arma::cos(c * x)) / n)
           + a + std::exp(1.0);
}

Rcpp::List result_list(const bool success, const arma::vec& par,
                       const optim::algo_settings_t& settings)
{
    return Rcpp::List::create(
        Rcpp::Named("par") = Rcpp::NumericVector(par.begin(), par.end()),
        Rcpp::Named("value") = settings.opt_fn_value,
        Rcpp::Named("iterations") = static_cast<int>(settings.opt_iter),
        Rcpp::Named("success") = success);
}

} // namespace

//' Minimize the sphere function with BFGS (C++ objective)
//'
//' Demonstrates calling `optim::bfgs()` on an objective written entirely
//' in C++, with an analytic gradient.
//'
//' @param x0 Numeric vector of starting values.
//' @return A list with elements `par`, `value`, `iterations` and `success`.
//' @examples
//' optim_sphere_bfgs(c(2, -3, 4))
//' @export
// [[Rcpp::export]]
Rcpp::List optim_sphere_bfgs(arma::vec x0)
{
    optim::algo_settings_t settings;
    const bool success = optim::bfgs(x0, sphere_fn, nullptr, settings);
    return result_list(success, x0, settings);
}

//' Minimize the Ackley function with Differential Evolution (C++ objective)
//'
//' Demonstrates a derivative-free global optimizer on a multimodal
//' function. Box bounds and the RNG seed are set through
//' `optim::algo_settings_t`.
//'
//' @param x0 Numeric vector of starting values.
//' @param seed Integer seed for OptimLib's internal RNG, for
//'   reproducibility.
//' @return A list with elements `par`, `value`, `iterations` and `success`.
//' @examples
//' optim_ackley_de(c(2, -2), seed = 42L)
//' @export
// [[Rcpp::export]]
Rcpp::List optim_ackley_de(arma::vec x0, int seed = 1)
{
    optim::algo_settings_t settings;
    settings.rng_seed_value = static_cast<size_t>(seed);
    settings.vals_bound = true;
    settings.lower_bounds = arma::vec(x0.n_elem, arma::fill::value(-5.0));
    settings.upper_bounds = arma::vec(x0.n_elem, arma::fill::value(5.0));
    const bool success = optim::de(x0, ackley_fn, nullptr, settings);
    return result_list(success, x0, settings);
}

//' Minimize an R function with BFGS via callbacks
//'
//' The objective and gradient are plain R functions, called from C++ on
//' every evaluation. Convenient, but the callback overhead makes this
//' slower than a C++ objective; for performance-critical work write the
//' objective in C++ against the OptimLib headers (see the vignette).
//'
//' @param fn R function taking a numeric vector, returning a scalar.
//' @param gr R function taking a numeric vector, returning the gradient
//'   vector.
//' @param x0 Numeric vector of starting values.
//' @return A list with elements `par`, `value`, `iterations` and `success`.
//' @examples
//' rosenbrock <- function(x) 100 * (x[2] - x[1]^2)^2 + (1 - x[1])^2
//' rosenbrock_gr <- function(x) c(
//'   -400 * x[1] * (x[2] - x[1]^2) - 2 * (1 - x[1]),
//'    200 * (x[2] - x[1]^2))
//' optimlib_bfgs(rosenbrock, rosenbrock_gr, c(-1.2, 1))
//' @export
// [[Rcpp::export]]
Rcpp::List optimlib_bfgs(Rcpp::Function fn, Rcpp::Function gr, arma::vec x0)
{
    auto objfn = [&fn, &gr](const arma::vec& x, arma::vec* grad_out,
                            void*) -> double {
        if (grad_out) {
            *grad_out = Rcpp::as<arma::vec>(gr(x));
        }
        return Rcpp::as<double>(fn(x));
    };

    optim::algo_settings_t settings;
    const bool success = optim::bfgs(x0, objfn, nullptr, settings);
    return result_list(success, x0, settings);
}

//' Minimize an R function with Nelder-Mead via callbacks
//'
//' Derivative-free minimization of a plain R function, so no gradient
//' function is needed. Same callback-overhead caveat as [optimlib_bfgs()].
//'
//' @param fn R function taking a numeric vector, returning a scalar.
//' @param x0 Numeric vector of starting values.
//' @return A list with elements `par`, `value`, `iterations` and `success`.
//' @examples
//' optimlib_nm(function(x) sum((x - 3)^2), c(0, 0))
//' @export
// [[Rcpp::export]]
Rcpp::List optimlib_nm(Rcpp::Function fn, arma::vec x0)
{
    auto objfn = [&fn](const arma::vec& x, arma::vec*, void*) -> double {
        return Rcpp::as<double>(fn(x));
    };

    optim::algo_settings_t settings;
    const bool success = optim::nm(x0, objfn, nullptr, settings);
    return result_list(success, x0, settings);
}
