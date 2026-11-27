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

* local: Ubuntu 26.04, R 4.6.1, g++ 15.2 (`--as-cran`) — 0 errors,
  0 warnings, 3 NOTEs (see below); also compiled cleanly with
  `-Wall -pedantic`
* R-hub (R-devel): Windows x86_64 (ucrt, Rtools45), macOS x86_64,
  macOS arm64 and Linux clang-asan (AddressSanitizer + UBSan) — Status
  OK, no compiler warnings, no sanitizer reports
* win-builder (R-devel, R-release, R-oldrelease) — 0 errors, 0 warnings
* mac-builder (R-release, arm64) — 0 errors, 0 warnings

The package checks cleanly on all platforms above.

## R CMD check results

0 errors | 0 warnings | 1 NOTE on CRAN's check services.

* "New submission" — expected for a first submission.

Two further NOTEs appear only locally and are not caused by the package:

* The non-portable compilation flag `-mno-omit-leaf-frame-pointer`,
  which comes from R's own default `CXX17FLAGS` on Debian/Ubuntu builds
  (the package's `src/Makevars` sets only `CXX_STD`, `PKG_CPPFLAGS` and
  the standard `PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)`).
* HTML manual validation skipped because HTML Tidy is not installed
  locally.

## Bundled third-party code

`inst/include/` contains the header-only build of 'OptimLib' and its
'BaseMatrixOps' dependency, both Copyright (c) 2016-2023 Keith O'Hara and
released under the Apache License 2.0. Keith O'Hara is credited in
`Authors@R` as author and copyright holder (`aut`, `cph`); the licensing
is recorded in `inst/COPYRIGHTS`, `inst/include/optimlib-LICENSE` and
`inst/include/optimlib-NOTICE.txt`. The package itself is GPL (>= 3),
since the Apache License 2.0 is compatible with GPL-3 but not GPL-2.

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
gcc in header-only mode; the package links R's BLAS/LAPACK via
`PKG_LIBS`, as for any 'RcppArmadillo' package. The package builds and
passes all checks on Windows (win-builder R-devel, R-release and
R-oldrelease; R-hub Windows).
