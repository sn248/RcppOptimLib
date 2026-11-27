## Submission

This is a new submission of RcppOptimLib 0.0.1.

The package provides an R interface to 'OptimLib'
(<https://github.com/kthohr/optim>), a header-only C++ library of
numerical optimization methods built on 'Armadillo'. The header-only
version of the library is bundled in `inst/include/` so that other R
packages can use it via `LinkingTo: RcppOptimLib` (the same model as
'RcppEnsmallen'), alongside a small set of R-callable demonstration
wrappers.

## Test environments

* local: Ubuntu Linux, R 4.6.1, gcc 13 — 0 errors, 0 warnings, 2 NOTEs
  (see below)
* win-builder (devel and release) — PENDING
* macOS (R-hub / mac-builder) — PENDING

(Update this section with the actual win-builder and macOS results before
submitting.)

## R CMD check results

0 errors | 0 warnings | 2 NOTEs on CRAN's machines.

* "New submission" — expected for a first submission.

* A local-only NOTE about the non-portable compilation flag
  `-mno-omit-leaf-frame-pointer` appears on Debian/Ubuntu builds. It
  originates from R's own default `CXX17FLAGS` on that platform, not from
  the package (the package's `src/Makevars` sets only `CXX_STD = CXX17`
  and `PKG_CPPFLAGS`), and does not appear on CRAN's build machines.

## Bundled third-party code

`inst/include/` contains the header-only build of 'OptimLib' and its
'BaseMatrixOps' dependency, both Copyright (c) 2016-2023 Keith O'Hara and
released under the Apache License 2.0. Keith O'Hara is credited in
`Authors@R` as author and copyright holder (`aut`, `cph`); the licensing
is recorded in `inst/COPYRIGHTS`, `inst/include/optimlib-LICENSE` and
`inst/include/optimlib-NOTICE.txt`. The package itself is GPL (>= 2).

Two mechanical modifications were applied to the vendored headers for use
inside R, documented in `IMPLEMENTATION.md`:

* index-vector typedefs changed to `arma::uword` (required by Armadillo
  >= 12 index-vector overloads on LP64 platforms);
* console output (`std::cout` / `std::cerr` / `printf`) routed through
  `Rcpp::Rcout` / `Rcpp::Rcerr` / `Rprintf`, per CRAN policy on compiled
  code writing to stdout/stderr.

## Notes for the CRAN team

Upstream OptimLib historically stated that Windows was unsupported; that
predates its header-only mode. The bundled headers compile with Rtools'
gcc in header-only mode. The win-builder results above confirm this
before submission.
