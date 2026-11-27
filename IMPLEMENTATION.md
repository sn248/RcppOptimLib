# RcppOptimLib — Implementation Plan

An R interface to [OptimLib](https://github.com/kthohr/optim), Keith
O'Hara's header-only C++ library of numerical optimization methods
(BFGS, L-BFGS, CG, gradient descent, Newton, Nelder–Mead, differential
evolution, PSO, SUMT constrained optimization, and root finding), built
on Armadillo. The package follows the `Rcppautodiff` / `RcppEnsmallen`
model: ship the headers in `inst/include/` so client packages can use
`LinkingTo: RcppOptimLib`, plus a small set of R-callable wrappers.

## Status

**Phase 0 and most of Phase 1 are done and verified**: the package
compiles against Rcpp 1.1.2 / RcppArmadillo 15.4.2.1 on R 4.6.1 (Linux,
gcc 13), and all 10 tinytest tests pass (BFGS and DE with C++
objectives; BFGS and Nelder–Mead with R-function callbacks).

## Key design decisions (already implemented)

1. **Flat header layout.** OptimLib's headers use include paths relative
   to the library root (`"misc/optim_structs.hpp"`,
   `"BaseMatrixOps/include/BaseMatrixOps.hpp"`), so they sit directly in
   `inst/include/` — not in a subdirectory. `LinkingTo` puts exactly one
   directory (`<pkg>/include`) on the compiler search path, and this is
   the only layout that works for client packages without patching every
   include in the library.

2. **`inst/include/RcppOptimLib.h` is the single entry point.** It
   defines `OPTIM_USE_RCPP_ARMADILLO` (OptimLib then includes
   `<RcppArmadillo.h>` itself — without this flag, RcppArmadillo's and
   system Armadillo's configurations mix and fail to link) and
   `OPTIM_DONT_USE_OPENMP`, then includes `optim.hpp`. Because the
   defines live in the header rather than in `src/Makevars`, client
   packages inherit them automatically.

3. **OpenMP is off by default.** OptimLib auto-enables OpenMP whenever
   `_OPENMP` is defined, and its parallel metaheuristics (DE, PSO)
   evaluate the objective from worker threads. R's C API is
   single-threaded, so an R-function callback objective under OpenMP
   would crash the session. A client package that uses only pure C++
   objectives may opt back in by defining `RCPPOPTIMLIB_ALLOW_OPENMP`
   before including `RcppOptimLib.h` and adding
   `$(SHLIB_OPENMP_CXXFLAGS)` to its own Makevars.

4. **Two patches to the vendored code**:
   - Index-vector typedefs (marked `[RcppOptimLib patch]` in
     `misc/optim_options.hpp`): `ColVecUInt_t`/`RowVecUInt_t` changed
     from `arma::Col<unsigned long long>` to `arma::Col<arma::uword>`.
     On LP64 Linux `arma::uword` is `unsigned long`, a distinct type
     from `unsigned long long`, and Armadillo ≥ 12 index-vector
     overloads (`X.rows(uvec)`, `X(uvec)`) reject the upstream type.
     Worth offering upstream as a PR.
   - Console output: `std::cout`/`std::cerr`/`printf` replaced
     mechanically (sed) with `Rcpp::Rcout`/`Rcpp::Rcerr`/`Rprintf`
     across the headers — CRAN forbids compiled code writing to
     stdout/stderr, and `R CMD check` flags the symbols even when the
     print paths are disabled at runtime. Also pruned:
     `BaseMatrixOps/.git`, `.github/` and `tests/` (hidden-file NOTE
     and a GNU-Makefile WARNING in check).

5. **Licensing.** The package is GPL (>= 3) (Apache-2.0 is
   compatible with GPL-3 but not GPL-2); the bundled OptimLib and
   BaseMatrixOps headers are Apache-2.0, Copyright Keith O'Hara, who is
   listed in `Authors@R` as `aut, cph`. See `inst/COPYRIGHTS`,
   `inst/include/optimlib-LICENSE` and `inst/include/optimlib-NOTICE.txt`.

## Vendored version / regeneration recipe

Bundled: OptimLib master commit `5453f48` (2024-04-28) with BaseMatrixOps
submodule commit `9e5beec`, generated in header-only mode. To upgrade:

```sh
git clone https://github.com/kthohr/optim.git && cd optim
git submodule update --init
./configure --header-only-version        # inlines the .cpp sources
# then replace the contents of inst/include/ (keep RcppOptimLib.h,
# optimlib-LICENSE, optimlib-NOTICE.txt) with header_only_version/*
```

After regenerating, re-apply the patches from decision 4 (the
`ColVecUInt_t` typedefs, the console-output sed, and the BaseMatrixOps
pruning) if not fixed upstream, and record the new commit hashes here.

```sh
# console-output patch, run from inst/include/:
files=$(grep -rl 'std::cout\|std::cerr\|printf(' --include='*.hpp' --include='*.ipp' .)
sed -i 's/std::cout/Rcpp::Rcout/g; s/std::cerr/Rcpp::Rcerr/g; s/\bprintf(/Rprintf(/g' $files
rm -rf BaseMatrixOps/.git BaseMatrixOps/.github BaseMatrixOps/tests
```

## Phase 1 — header-shipping core (mostly done)

- [x] Vendor header-only OptimLib + BaseMatrixOps into `inst/include/`
- [x] `RcppOptimLib.h` wrapper header with the RcppArmadillo/OpenMP defines
- [x] `src/Makevars`: `CXX_STD = CXX17`,
      `PKG_CPPFLAGS = -I../inst/include/` (also used on Windows; no
      separate `Makevars.win` needed)
- [x] Demo exports with C++ objectives: `optim_sphere_bfgs()` (BFGS,
      analytic gradient), `optim_ackley_de()` (differential evolution,
      box bounds, seeded RNG)
- [x] Demo exports with R callbacks: `optimlib_bfgs(fn, gr, x0)`,
      `optimlib_nm(fn, x0)`
- [x] tinytest suite; roxygen2 docs; `Rcpp::compileAttributes()`
- [ ] `R CMD check --as-cran` clean locally (run after every phase)
- [ ] Verify a client package / `Rcpp::sourceCpp()` snippet with
      `// [[Rcpp::depends(RcppOptimLib, RcppArmadillo)]]` compiles using
      only `#include <RcppOptimLib.h>` (this is the LinkingTo contract —
      add it as a test, e.g. skipped on CRAN)

## Phase 2 — a real R-level interface

Goal: one `optimlib()` front end resembling `stats::optim()`:

- [ ] `optimlib(par, fn, gr = NULL, method = c("bfgs","lbfgs","cg","gd",
      "nm","de","pso"), lower = NULL, upper = NULL, control = list())`
- [ ] Map `control` onto `optim::algo_settings_t` (iter_max,
      grad_err_tol, rel_sol_change_tol, per-algorithm sub-settings such
      as `de_settings.n_pop`); document defaults in `?optimlib`
- [ ] When `gr` is NULL for gradient-based methods, fall back to
      OptimLib's numerical gradient or refuse with a clear error —
      decide and document
- [ ] RNG: always route a user-suppliable seed into
      `settings.rng_seed_value` (OptimLib uses its own `std::mt19937_64`,
      not R's RNG stream); consider seeding from R's RNG via
      `R::runif()` so `set.seed()` affects results
- [ ] Wrap R callback exceptions: an R error inside `fn` must not
      longjmp through C++ frames — catch with `Rcpp::Function` semantics
      and return a proper error (add a test that `fn = stop("boom")`
      fails cleanly)
- [ ] Return a classed object (`optimlib_result`) with `print()` method:
      par, value, iterations, success, method, settings used

## Phase 3 — client-package story and docs

- [ ] Vignette 1: using OptimLib from `sourceCpp()`/own package via
      LinkingTo (the fast path), including passing data through
      `opt_data` and a benchmark against the R-callback path
- [ ] Vignette 2: the R-level `optimlib()` interface, comparison with
      `stats::optim()` and `optimx` on standard test problems
- [ ] pkgdown site (mirror the Rcppautodiff `_pkgdown.yml` setup)
- [ ] GitHub Actions: R-CMD-check matrix (Linux/macOS/Windows,
      release/devel) — Windows is the one to watch (below)

## Phase 4 — CRAN readiness

- [ ] **Windows**: upstream declares Windows unsupported, but that
      statement predates header-only mode; it compiles with Rtools' gcc
      in principle. Verify on win-builder + GitHub Actions early — if it
      fails, either patch (and upstream the fix) or set `OS_type: unix`
      in DESCRIPTION and say so in cran-comments
- [ ] macOS: check clang build (no OpenMP flags are used, so the usual
      macOS OpenMP pain is avoided)
- [ ] `R CMD check --as-cran` + rhub on all platforms; fix compiler
      warnings from the vendored headers if CRAN flags them
      (`-Wall -pedantic`)
- [x] No `std::cout`/`printf` in compiled code paths (CRAN policy):
      patched to `Rcpp::Rcout`/`Rprintf` (decision 4); re-audit after
      any header upgrade
- [ ] cran-comments.md noting the bundled Apache-2.0 code, the single
      patch, and Windows status
- [ ] CRAN submission (mirror the Rcppautodiff CRAN-SUBMISSION workflow)

## Known risks / open questions

- **Windows support** (see Phase 4) — the main unknown.
- **`optim::lbfgs` terminates early** on the classic Rosenbrock test
  from (-1.2, 1): it stalls at (-1.017, 1.069) even with
  `iter_max = 2000` and tight tolerances, while `optim::bfgs` reaches
  (1, 1) on the identical objective (verified 2026-08-24 against the
  bundled commit). Investigate the upstream convergence check before
  exposing `lbfgs` through the Phase 2 R interface; add cross-algorithm
  convergence tests on standard problems (Rosenbrock, Beale, Wood).
- **Upstream activity**: the bundled commit is from April 2024; upstream
  moves slowly, so the `uword` patch may need to live here long-term.
- **`de_prmm`/`pso_dv` variants** call the objective from OpenMP regions
  even in some serial builds — audit before exposing them to R callbacks.
- **BaseMatrixOps trailing niceties**: `stats/` headers in the bundle
  include sampling helpers not needed for optimization; they compile
  fine but could be pruned to shrink the install footprint.
