# RcppOptimLib — Implementation Plan

An R interface to [OptimLib](https://github.com/kthohr/optim), Keith
O'Hara's header-only C++ library of numerical optimization methods
(BFGS, L-BFGS, CG, gradient descent, Newton, Nelder–Mead, differential
evolution, PSO, SUMT constrained optimization, and root finding), built
on Armadillo. The package follows the `Rcppautodiff` / `RcppEnsmallen`
model: ship the headers in `inst/include/` so client packages can use
`LinkingTo: RcppOptimLib`, plus an `optim()`-like R interface to every
algorithm.

## Status

- **0.0.1** (`main`): submitted to CRAN 2026-11-27 (commit `c1f877e`,
  recorded in `CRAN-SUBMISSION`). Headers + C++ demo exports +
  `optimlib_bfgs()` / `optimlib_nm()` callback wrappers. `R CMD check
  --as-cran` clean (only the "New submission" NOTE on CRAN machines) on
  local Linux, win-builder (devel/release/oldrelease), mac-builder and
  R-hub (Windows, macOS x86_64/arm64, clang-asan). pkgdown site live at
  <https://sn248.github.io/RcppOptimLib/>.
- **0.0.1.9000** (`dev-0.0.2` branch): Phase 2 implemented — general
  R interface `optimlib()`, `optimlib_sumt()`, `optimlib_root()`,
  `optimlib_control()`, plus three upstream bug fixes (decision 4).
  77 tinytest results pass; local `--as-cran` has 0 errors / 0 warnings;
  0 compiler warnings with `-Wall -pedantic`. Not yet merged to `main`
  or released.

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

4. **Patches to the vendored code**:
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
   - Upstream bug fixes (0.0.2 / `dev-0.0.2` only; each marked
     `RcppOptimLib patch` in the source, all present on upstream master
     as of 2026-11 and worth reporting/PRing):
     - `unconstrained/lbfgs.hpp`: `x` was not advanced to `x_p` after the
       first line search, so the first in-loop curvature pair used an `s`
       spanning two steps against a one-step `y`; L-BFGS stalled after 2
       iterations on Rosenbrock. The first-step `grad_err` also used the
       initial gradient instead of `grad_p`.
     - `unconstrained/pso_dv.hpp`: the stagnation-reset Hadamard product
       mixed a column vector (`rand_vec`) with a row vector
       (`P_max - P_min`); Armadillo throws at runtime.
     - `constrained/sumt.hpp`: penalty gradient was
       `c * colSums(J)` instead of `c * t(J) %*% g`, inconsistent with the
       penalized objective; BFGS stalled once the penalty grew
       (x + y <= 2 test stopped at 1.00046 instead of 1).

   Known upstream behaviours *not* patched, handled on the R side:
   `de_prmm` halves the population three times (hard-coded) and indexes
   with unsigned arithmetic, so `n_pop %/% 8 <= n_pop_best` reads out of
   bounds — `optimlib()` validates this. With `check_freq = Inf`, `de`
   reports success after `n_gen` generations but `de_prmm`/`pso`/`pso_dv`
   report failure — documented in `?optimlib`. `de_prmm` ignores `n_gen`
   (budget comes from `max_fn_eval` and `pmax`) — documented in
   `?optimlib_control`. `broyden_df` without a Jacobian can diverge to NaN
   from poor starts (e.g. `(1, 0.5)` on `x^2 + y^2 = 4, x = y`); treated
   as algorithmic, not a bug — documented in `?optimlib_root`.

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

After regenerating, re-apply the patches from decision 4 if not fixed
upstream — the `ColVecUInt_t` typedefs, the console-output sed, the
BaseMatrixOps pruning, and the three bug fixes in `lbfgs.hpp`,
`pso_dv.hpp` and `sumt.hpp` (`grep -rn "RcppOptimLib patch"` on the old
tree lists them) — then rerun the tinytest suite, which has regression
tests for each fix, and record the new commit hashes here.

```sh
# console-output patch, run from inst/include/:
files=$(grep -rl 'std::cout\|std::cerr\|printf(' --include='*.hpp' --include='*.ipp' .)
sed -i 's/std::cout/Rcpp::Rcout/g; s/std::cerr/Rcpp::Rcerr/g; s/\bprintf(/Rprintf(/g' $files
rm -rf BaseMatrixOps/.git BaseMatrixOps/.github BaseMatrixOps/tests
```

## Phase 1 — header-shipping core (done, 0.0.1)

- [x] Vendor header-only OptimLib + BaseMatrixOps into `inst/include/`
- [x] `RcppOptimLib.h` wrapper header with the RcppArmadillo/OpenMP defines
- [x] `src/Makevars`: `CXX_STD = CXX17`,
      `PKG_CPPFLAGS = -I../inst/include/` and
      `PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)`. The `PKG_LIBS`
      line is required: Armadillo calls BLAS/LAPACK, which libR happens to
      provide on Linux/macOS but not on Windows (link failure on
      win-builder without it). Client packages need the same line; this
      is documented in the README, vignette and `?RcppOptimLib`. Also
      used on Windows; no separate `Makevars.win`.
- [x] Demo exports with C++ objectives: `optim_sphere_bfgs()` (BFGS,
      analytic gradient), `optim_ackley_de()` (differential evolution,
      box bounds, seeded RNG)
- [x] R-callback wrappers `optimlib_bfgs(fn, gr, x0)`,
      `optimlib_nm(fn, x0)` (C++ in 0.0.1; R shortcuts for `optimlib()`
      from 0.0.2)
- [x] tinytest suite; roxygen2 docs; `Rcpp::compileAttributes()`
- [x] `R CMD check --as-cran` clean locally
- [ ] Verify a client package / `Rcpp::sourceCpp()` snippet with
      `// [[Rcpp::depends(RcppOptimLib, RcppArmadillo)]]` compiles using
      only `#include <RcppOptimLib.h>` (this is the LinkingTo contract —
      add it as a test, e.g. skipped on CRAN)

## Phase 2 — a real R-level interface (done on `dev-0.0.2`)

Implemented in `R/optimlib.R`, `R/control.R`, `R/wrappers.R` and
`src/interface.cpp`. All validation, defaults and finite differences are
on the R side; the C++ entry points (`.optimlib_min`, `.optimlib_sumt`,
`.optimlib_root`, unexported) assume a complete, validated control list.

- [x] `optimlib(par, fn, gr = NULL, ..., method, lower, upper, hess,
      control)` with all ten unconstrained methods: `bfgs`, `lbfgs`,
      `cg`, `gd`, `newton`, `nm`, `de`, `de_prmm`, `pso`, `pso_dv`.
      Box bounds on every method except `newton` (no upstream support);
      `par` must be strictly inside the bounds (OptimLib transforms them)
- [x] `optimlib_sumt()` (inequality constraints `constr(x) <= 0`) and
      `optimlib_root()` (`broyden`, `broyden_df`, optional Jacobian)
- [x] `optimlib_control()` maps onto `optim::algo_settings_t`: general
      tolerances plus one named list per algorithm mirroring OptimLib's
      `*_settings_t` structs; unknown names and invalid values are
      errors. `cg$method` / `gd$method` accept names (`"hz"`, `"adam"`)
      or upstream integer codes. Not exposed: `omp_n_threads` (OpenMP is
      off), NM custom initial simplex, DE/PSO population-matrix return
- [x] Missing derivatives: central finite differences computed in R
      (gradient; Hessian as symmetrized Jacobian of the gradient;
      constraint Jacobian for SUMT), not OptimLib's numerical helpers
- [x] RNG: when `control$seed` is NULL, stochastic methods draw a seed
      from R's RNG (`sample.int`), so `set.seed()` gives reproducible
      results; deterministic methods do not touch `.Random.seed`
- [x] R errors in callbacks: `Rcpp::Function` evaluates with unwind
      protection, so an R error becomes a C++ exception that unwinds
      through OptimLib's frames (which hold only RAII objects and have no
      `catch` blocks) to the Rcpp export wrapper. Tested
      (`stop("boom")`, including after the first evaluation)
- [x] Callbacks receive a plain numeric vector (0.0.1 passed an n x 1
      matrix — noted in NEWS as a behaviour change); return lengths and
      dimensions are checked in C++ with informative errors
- [ ] Return a classed object (`optimlib_result`) with a `print()`
      method — currently a plain list: `par`, `value`, `success`,
      `iterations`, `error`, `method` (`fn_values` instead of `value`
      for root finding)

## Phase 3 — client-package story and docs

- [x] pkgdown site, deployed to GitHub Pages by
      `.github/workflows/pkgdown.yaml` on every push to `main`
- [x] Single vignette covering both paths (R interface, and C++ via
      LinkingTo / `sourceCpp()`); updated for `optimlib()` on `dev-0.0.2`
- [ ] Vignette material still missing: passing data through `opt_data`,
      a benchmark of the C++ path against R callbacks, and comparison
      with `stats::optim()` / `optimx` on standard test problems
- [ ] GitHub Actions R-CMD-check matrix on push/PR. Only the manual
      R-hub workflow (`.github/workflows/rhub.yaml`) exists today

## Phase 4 — CRAN readiness (done for 0.0.1)

- [x] **Windows**: builds and passes on win-builder and R-hub once
      `PKG_LIBS` links BLAS/LAPACK (see Phase 1); no `OS_type`
      restriction needed
- [x] macOS: R-hub x86_64 and arm64, and mac-builder, pass
- [x] `R CMD check --as-cran` + R-hub (Windows, macOS, clang-asan with
      ASan/UBSan: no sanitizer reports); 0 compiler warnings with
      `-Wall -pedantic`
- [x] No `std::cout`/`printf` in compiled code paths (CRAN policy):
      patched to `Rcpp::Rcout`/`Rprintf` (decision 4); re-audit after
      any header upgrade
- [x] `cran-comments.md` (bundled Apache-2.0 code, vendored-header
      modifications, Windows status, test environments)
- [x] CRAN submission of 0.0.1 (`devtools::submit_cran()`;
      `CRAN-SUBMISSION` committed)
- [ ] For 0.0.2: update `cran-comments.md` to mention the three
      upstream bug fixes in the vendored headers; rerun win-builder,
      mac-builder and R-hub on the release candidate

## Known risks / open questions

- **Upstream activity**: the bundled commit is from April 2024 and
  upstream moves slowly, so the `uword` patch and the three bug fixes
  may need to live here long-term. Report the bugs upstream so a future
  regeneration can drop them.
- **Population-method `success` semantics** are inconsistent upstream
  (see decision 4); a future version could normalize them on the R side
  instead of only documenting them.
- **OpenMP**: every `#pragma omp` in the bundled headers is guarded by
  `#ifdef OPTIM_USE_OPENMP`, which `optim_options.hpp` never defines
  when `OPTIM_DONT_USE_OPENMP` is set (as `RcppOptimLib.h` does), so R
  callbacks are never invoked from worker threads (audited 2026-11-27).
  Re-audit after any header upgrade.
- **BaseMatrixOps trailing niceties**: `stats/` headers in the bundle
  include sampling helpers not needed for optimization; they compile
  fine but could be pruned to shrink the install footprint.
