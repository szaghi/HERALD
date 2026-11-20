# Quick Start

```fortran
use herald
```

The handler is not written yet; this page follows it.

## Tests

```bash
fobis build --mode tests-gnu && bash scripts/run_tests.sh          # MPI tests on 2 ranks (--np N)
fobis clean --mode tests-gnu-serial
fobis build --mode tests-gnu-serial && bash scripts/run_tests.sh   # no MPI library
fobis rule --ex makecoverage-analysis   # what CI runs: coverage into docs/public/coverage.json
```

`exe/` is shared by the test modes: clean before switching mode or compiler.
