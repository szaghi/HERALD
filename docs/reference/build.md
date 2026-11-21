# Build: macros and modes

## Macros

| Macro | Effect |
|---|---|
| `HERALD_NO_MPI` | no MPI library: one rank, the same interface ([recipe](/cookbook/serial)) |
| `HERALD_OAC` | the device layer on OpenACC |
| `HERALD_OMP` | the device layer on OpenMP target offloading |
| `HERALD_HIP` | with `HERALD_OMP`: the device memory from AMD's HIP runtime (link `libamdhip64`) |

Two modules hold every preprocessor directive: `herald_mpi` (MPI or its stand-in) and `herald_device_backend` (the
device runtime or its stand-in).

## FoBiS modes

`fobis build --lmodes` lists them; `fobis build --mode <mode>`.

| Mode | Builds |
|---|---|
| `static-gnu`, `shared-gnu` | the MPI library with gfortran: `lib/gnu/static/libherald.a`, `lib/gnu/shared/libherald.so` |
| `static-nvf`, `shared-nvf` | with nvfortran |
| `static-intel`, `shared-intel` | with ifx |
| `static-gnu-serial`, `static-nvf-serial`, `static-intel-serial` | the serial library, `libherald_serial.a` |
| `static-nvf-oac` | the MPI library with the OpenACC device layer, nvfortran |
| `tests-gnu`, `tests-nvf`, `tests-intel` | the tests into `exe/`, optimised |
| `tests-gnu-debug`, `tests-nvf-debug`, `tests-intel-debug` | with every check on |
| `tests-gnu-coverage` | with coverage instrumentation |
| `tests-gnu-serial`, `tests-nvf-serial` | the tests of the serial library |
| `tests-gnu-omp` | the tests with the OpenMP device layer, into `exe-omp/` |
| `tests-nvf-oac` | the tests with the OpenACC device layer, into `exe-oac/` |

`--varset cc80|cc89|cc90|iac` picks the NVIDIA compute capability of the OpenACC modes (cc89 by default).

`exe/` is shared by the test modes: `fobis clean --mode <mode>` before switching mode or compiler.

## Rules

| `fobis rule --ex` | |
|---|---|
| `makecoverage` | build the tests with coverage and run them |
| `makecoverage-analysis` | the same, then the coverage badge (what CI runs) |
| `makedoc` | the API pages and the VitePress site |
| `clean` | remove the build products |

## Scripts

| Script | |
|---|---|
| `scripts/run_tests.sh [--np N] [--exe-dir DIR]` | run every test of `exe/` (or `DIR`); MPI tests on 2 ranks (or `N`) |
| `scripts/docs_examples.sh` | build and run the documentation examples, regenerate their snippets and outputs |
| `scripts/ci/matrix.sh` | what the CI matrix runs on each toolchain |
| `scripts/install.sh`, `scripts/release.sh` | install a release; make one |
