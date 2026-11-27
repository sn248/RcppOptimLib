// Demonstration functions for RcppOptimLib.
//
// Pure C++ objectives (optim_sphere_bfgs, optim_ackley_de): the fast path,
// and the model for client packages using LinkingTo. The general R-callback
// interface (optimlib() and friends) lives in interface.cpp.

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
