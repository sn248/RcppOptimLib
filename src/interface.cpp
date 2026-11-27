// General R-callback interface to OptimLib: optimlib(), optimlib_sumt()
// and optimlib_root(). All argument validation, defaults and numerical
// derivatives live on the R side (R/optimlib.R, R/control.R); these
// functions assume a complete, validated control list.

#include <RcppOptimLib.h>

#include <limits>
#include <memory>
#include <string>

// [[Rcpp::depends(RcppArmadillo)]]

namespace {

// Values are passed to R as plain numeric vectors (not n x 1 matrices).
Rcpp::NumericVector to_r(const arma::vec& x)
{
    return Rcpp::NumericVector(x.begin(), x.end());
}

double call_scalar(Rcpp::Function& f, const arma::vec& x, const char* what)
{
    Rcpp::NumericVector res(f(to_r(x)));
    if (res.size() != 1) {
        Rcpp::stop("`%s` must return a single numeric value, not length %d.",
                   what, static_cast<int>(res.size()));
    }
    return res[0];
}

arma::vec call_vector(Rcpp::Function& f, const arma::vec& x,
                      const arma::uword n, const char* what)
{
    Rcpp::NumericVector res(f(to_r(x)));
    if (static_cast<arma::uword>(res.size()) != n) {
        Rcpp::stop("`%s` must return a numeric vector of length %d, not %d.",
                   what, static_cast<int>(n), static_cast<int>(res.size()));
    }
    return arma::vec(res.begin(), res.size());
}

arma::mat call_matrix(Rcpp::Function& f, const arma::vec& x,
                      const arma::uword nr, const arma::uword nc,
                      const char* what)
{
    Rcpp::NumericMatrix res(f(to_r(x)));
    if (static_cast<arma::uword>(res.nrow()) != nr ||
        static_cast<arma::uword>(res.ncol()) != nc) {
        Rcpp::stop("`%s` must return a %d x %d matrix, not %d x %d.", what,
                   static_cast<int>(nr), static_cast<int>(nc),
                   res.nrow(), res.ncol());
    }
    return arma::mat(res.begin(), nr, nc);
}

template <typename T>
T get(const Rcpp::List& l, const char* name)
{
    return Rcpp::as<T>(l[name]);
}

// Counts arrive as doubles; Inf means "never" (OptimLib uses size_t(-1)).
std::size_t get_count(const Rcpp::List& l, const char* name)
{
    const double v = get<double>(l, name);
    if (!std::isfinite(v)) {
        return std::numeric_limits<std::size_t>::max();
    }
    return static_cast<std::size_t>(v);
}

arma::vec get_vec_or_empty(const Rcpp::List& l, const char* name)
{
    SEXP x = l[name];
    return Rf_isNull(x) ? arma::vec() : Rcpp::as<arma::vec>(x);
}

optim::algo_settings_t settings_from_control(const Rcpp::List& ctrl,
                                             const arma::vec& lower,
                                             const arma::vec& upper)
{
    optim::algo_settings_t s;

    // Not every code path in OptimLib sets these; avoid returning garbage.
    s.opt_iter = 0;
    s.opt_error_value = NA_REAL;

    s.rng_seed_value = static_cast<std::size_t>(get<double>(ctrl, "seed"));
    s.print_level = get<int>(ctrl, "print_level");
    s.conv_failure_switch = get<int>(ctrl, "conv_failure_switch");
    s.iter_max = get_count(ctrl, "iter_max");
    s.grad_err_tol = get<double>(ctrl, "grad_err_tol");
    s.rel_sol_change_tol = get<double>(ctrl, "rel_sol_change_tol");
    s.rel_objfn_change_tol = get<double>(ctrl, "rel_objfn_change_tol");

    if (lower.n_elem > 0) {
        s.vals_bound = true;
        s.lower_bounds = lower;
        s.upper_bounds = upper;
    }

    const Rcpp::List bfgs = ctrl["bfgs"];
    s.bfgs_settings.wolfe_cons_1 = get<double>(bfgs, "wolfe_cons_1");
    s.bfgs_settings.wolfe_cons_2 = get<double>(bfgs, "wolfe_cons_2");

    const Rcpp::List lbfgs = ctrl["lbfgs"];
    s.lbfgs_settings.par_M = get_count(lbfgs, "par_M");
    s.lbfgs_settings.wolfe_cons_1 = get<double>(lbfgs, "wolfe_cons_1");
    s.lbfgs_settings.wolfe_cons_2 = get<double>(lbfgs, "wolfe_cons_2");

    const Rcpp::List cg = ctrl["cg"];
    s.cg_settings.method = get<int>(cg, "method");
    s.cg_settings.restart_threshold = get<double>(cg, "restart_threshold");
    s.cg_settings.use_rel_sol_change_crit =
        get<bool>(cg, "use_rel_sol_change_crit");
    s.cg_settings.wolfe_cons_1 = get<double>(cg, "wolfe_cons_1");
    s.cg_settings.wolfe_cons_2 = get<double>(cg, "wolfe_cons_2");

    const Rcpp::List gd = ctrl["gd"];
    s.gd_settings.method = get<int>(gd, "method");
    s.gd_settings.par_step_size = get<double>(gd, "par_step_size");
    s.gd_settings.step_decay = get<bool>(gd, "step_decay");
    s.gd_settings.step_decay_periods = get_count(gd, "step_decay_periods");
    s.gd_settings.step_decay_val = get<double>(gd, "step_decay_val");
    s.gd_settings.par_momentum = get<double>(gd, "par_momentum");
    s.gd_settings.par_ada_norm_term = get<double>(gd, "par_ada_norm_term");
    s.gd_settings.par_ada_rho = get<double>(gd, "par_ada_rho");
    s.gd_settings.ada_max = get<bool>(gd, "ada_max");
    s.gd_settings.par_adam_beta_1 = get<double>(gd, "par_adam_beta_1");
    s.gd_settings.par_adam_beta_2 = get<double>(gd, "par_adam_beta_2");
    s.gd_settings.clip_grad = get<bool>(gd, "clip_grad");
    s.gd_settings.clip_max_norm = get<bool>(gd, "clip_max_norm");
    s.gd_settings.clip_min_norm = get<bool>(gd, "clip_min_norm");
    s.gd_settings.clip_norm_type = get<int>(gd, "clip_norm_type");
    s.gd_settings.clip_norm_bound = get<double>(gd, "clip_norm_bound");

    const Rcpp::List nm = ctrl["nm"];
    s.nm_settings.adaptive_pars = get<bool>(nm, "adaptive_pars");
    s.nm_settings.par_alpha = get<double>(nm, "par_alpha");
    s.nm_settings.par_beta = get<double>(nm, "par_beta");
    s.nm_settings.par_gamma = get<double>(nm, "par_gamma");
    s.nm_settings.par_delta = get<double>(nm, "par_delta");

    const Rcpp::List de = ctrl["de"];
    s.de_settings.n_pop = get_count(de, "n_pop");
    s.de_settings.n_pop_best = get_count(de, "n_pop_best");
    s.de_settings.n_gen = get_count(de, "n_gen");
    s.de_settings.mutation_method = get_count(de, "mutation_method");
    s.de_settings.check_freq = get_count(de, "check_freq");
    s.de_settings.par_F = get<double>(de, "par_F");
    s.de_settings.par_CR = get<double>(de, "par_CR");
    s.de_settings.pmax = get<int>(de, "pmax");
    s.de_settings.max_fn_eval = get_count(de, "max_fn_eval");
    s.de_settings.par_F_l = get<double>(de, "par_F_l");
    s.de_settings.par_F_u = get<double>(de, "par_F_u");
    s.de_settings.par_tau_F = get<double>(de, "par_tau_F");
    s.de_settings.par_tau_CR = get<double>(de, "par_tau_CR");
    s.de_settings.par_d_eps = get<double>(de, "par_d_eps");
    s.de_settings.initial_lb = get_vec_or_empty(de, "initial_lb");
    s.de_settings.initial_ub = get_vec_or_empty(de, "initial_ub");

    const Rcpp::List pso = ctrl["pso"];
    s.pso_settings.center_particle = get<bool>(pso, "center_particle");
    s.pso_settings.n_pop = get_count(pso, "n_pop");
    s.pso_settings.n_gen = get_count(pso, "n_gen");
    s.pso_settings.check_freq = get_count(pso, "check_freq");
    s.pso_settings.inertia_method = get<int>(pso, "inertia_method");
    s.pso_settings.par_w = get<double>(pso, "par_w");
    s.pso_settings.par_w_damp = get<double>(pso, "par_w_damp");
    s.pso_settings.par_w_min = get<double>(pso, "par_w_min");
    s.pso_settings.par_w_max = get<double>(pso, "par_w_max");
    s.pso_settings.velocity_method = get<int>(pso, "velocity_method");
    s.pso_settings.par_c_cog = get<double>(pso, "par_c_cog");
    s.pso_settings.par_c_soc = get<double>(pso, "par_c_soc");
    s.pso_settings.par_final_c_cog = get<double>(pso, "par_final_c_cog");
    s.pso_settings.par_final_c_soc = get<double>(pso, "par_final_c_soc");
    s.pso_settings.initial_lb = get_vec_or_empty(pso, "initial_lb");
    s.pso_settings.initial_ub = get_vec_or_empty(pso, "initial_ub");

    const Rcpp::List sumt = ctrl["sumt"];
    s.sumt_settings.par_eta = get<double>(sumt, "par_eta");

    const Rcpp::List broyden = ctrl["broyden"];
    s.broyden_settings.par_rho = get<double>(broyden, "par_rho");
    s.broyden_settings.par_sigma_1 = get<double>(broyden, "par_sigma_1");
    s.broyden_settings.par_sigma_2 = get<double>(broyden, "par_sigma_2");

    return s;
}

Rcpp::List min_result(const arma::vec& par, const double value,
                      const bool success,
                      const optim::algo_settings_t& settings)
{
    return Rcpp::List::create(
        Rcpp::Named("par") = to_r(par),
        Rcpp::Named("value") = value,
        Rcpp::Named("success") = success,
        Rcpp::Named("iterations") = static_cast<double>(settings.opt_iter),
        Rcpp::Named("error") = settings.opt_error_value);
}

} // namespace

// [[Rcpp::export(.optimlib_min)]]
Rcpp::List optimlib_min_cpp(const std::string& method, arma::vec par,
                            Rcpp::Function fn, SEXP gr, SEXP hess,
                            const arma::vec& lower, const arma::vec& upper,
                            const Rcpp::List& control)
{
    optim::algo_settings_t settings =
        settings_from_control(control, lower, upper);
    const arma::uword n = par.n_elem;
    bool success = false;

    if (method == "newton") {
        Rcpp::Function grf(gr), hessf(hess);
        auto objfn = [&](const arma::vec& x, arma::vec* grad_out,
                         arma::mat* hess_out, void*) -> double {
            if (grad_out) *grad_out = call_vector(grf, x, n, "gr");
            if (hess_out) *hess_out = call_matrix(hessf, x, n, n, "hess");
            return call_scalar(fn, x, "fn");
        };
        success = optim::newton(par, objfn, nullptr, settings);
        return min_result(par, call_scalar(fn, par, "fn"), success, settings);
    }

    // Derivative-free methods never request a gradient, so `gr` may be NULL.
    std::unique_ptr<Rcpp::Function> grf;
    if (!Rf_isNull(gr)) {
        grf.reset(new Rcpp::Function(gr));
    }
    auto objfn = [&](const arma::vec& x, arma::vec* grad_out,
                     void*) -> double {
        if (grad_out) {
            if (!grf) {
                Rcpp::stop("Internal error: `%s` requested a gradient.",
                           method.c_str());
            }
            *grad_out = call_vector(*grf, x, n, "gr");
        }
        return call_scalar(fn, x, "fn");
    };

    if (method == "bfgs") {
        success = optim::bfgs(par, objfn, nullptr, settings);
    } else if (method == "lbfgs") {
        success = optim::lbfgs(par, objfn, nullptr, settings);
    } else if (method == "cg") {
        success = optim::cg(par, objfn, nullptr, settings);
    } else if (method == "gd") {
        success = optim::gd(par, objfn, nullptr, settings);
    } else if (method == "nm") {
        success = optim::nm(par, objfn, nullptr, settings);
    } else if (method == "de") {
        success = optim::de(par, objfn, nullptr, settings);
    } else if (method == "de_prmm") {
        success = optim::de_prmm(par, objfn, nullptr, settings);
    } else if (method == "pso") {
        success = optim::pso(par, objfn, nullptr, settings);
    } else if (method == "pso_dv") {
        success = optim::pso_dv(par, objfn, nullptr, settings);
    } else {
        Rcpp::stop("Unknown method '%s'.", method.c_str());
    }

    return min_result(par, call_scalar(fn, par, "fn"), success, settings);
}

// [[Rcpp::export(.optimlib_sumt)]]
Rcpp::List optimlib_sumt_cpp(arma::vec par, Rcpp::Function fn,
                             Rcpp::Function gr, Rcpp::Function constr,
                             Rcpp::Function constr_jac, const int n_constr,
                             const Rcpp::List& control)
{
    optim::algo_settings_t settings =
        settings_from_control(control, arma::vec(), arma::vec());
    const arma::uword n = par.n_elem;
    const arma::uword m = static_cast<arma::uword>(n_constr);

    auto objfn = [&](const arma::vec& x, arma::vec* grad_out,
                     void*) -> double {
        if (grad_out) *grad_out = call_vector(gr, x, n, "gr");
        return call_scalar(fn, x, "fn");
    };
    auto constrfn = [&](const arma::vec& x, arma::mat* jacob_out,
                        void*) -> arma::vec {
        if (jacob_out) {
            *jacob_out = call_matrix(constr_jac, x, m, n, "constr_jac");
        }
        return call_vector(constr, x, m, "constr");
    };

    const bool success =
        optim::sumt(par, objfn, nullptr, constrfn, nullptr, settings);
    return min_result(par, call_scalar(fn, par, "fn"), success, settings);
}

// [[Rcpp::export(.optimlib_root)]]
Rcpp::List optimlib_root_cpp(const std::string& method, arma::vec par,
                             Rcpp::Function fn, SEXP jac,
                             const Rcpp::List& control)
{
    optim::algo_settings_t settings =
        settings_from_control(control, arma::vec(), arma::vec());
    const arma::uword n = par.n_elem;

    auto rootfn = [&](const arma::vec& x, void*) -> arma::vec {
        return call_vector(fn, x, n, "fn");
    };

    bool success = false;
    if (Rf_isNull(jac)) {
        success = (method == "broyden_df")
            ? optim::broyden_df(par, rootfn, nullptr, settings)
            : optim::broyden(par, rootfn, nullptr, settings);
    } else {
        Rcpp::Function jacf(jac);
        auto jacfn = [&](const arma::vec& x, void*) -> arma::mat {
            return call_matrix(jacf, x, n, n, "jac");
        };
        success = (method == "broyden_df")
            ? optim::broyden_df(par, rootfn, nullptr, jacfn, nullptr, settings)
            : optim::broyden(par, rootfn, nullptr, jacfn, nullptr, settings);
    }

    return Rcpp::List::create(
        Rcpp::Named("par") = to_r(par),
        Rcpp::Named("fn_values") = to_r(call_vector(fn, par, n, "fn")),
        Rcpp::Named("success") = success,
        Rcpp::Named("iterations") = static_cast<double>(settings.opt_iter),
        Rcpp::Named("error") = settings.opt_error_value);
}
