# HERALD

**H**PC **E**nvironment, **R**anks, **A**ccounting, **L**ogging, **D**evices: the MPI handler of HPC codes, in modern
Fortran.

[![CI](https://github.com/szaghi/HERALD/actions/workflows/ci.yml/badge.svg)](https://github.com/szaghi/HERALD/actions/workflows/ci.yml)
[![Matrix](https://github.com/szaghi/HERALD/actions/workflows/matrix.yml/badge.svg)](https://github.com/szaghi/HERALD/actions/workflows/matrix.yml)

HERALD is the one handler an MPI code declares once: the process environment (communicator, rank, ranks of the run
and of the node), the accounting of time and memory (named timers, the memory budget of each rank), rank-prefixed
logging with a fatal path that stops every rank, and the binding of ranks to devices. It replaces the `mpih_object`
classes that ADAM and FUNDAL each carried. No dependencies: MPI, the compiler and Linux. Built without MPI
(`-DHERALD_NO_MPI`) it is a single-rank stub with the same interface.

The handler is written and tested on the host with gfortran and nvfortran, with and without MPI. Its device layer
(OpenACC) is compiled and tested on the host device type only: it has not run on a GPU yet. Not released.

```bash
fobis build --mode tests-gnu && bash scripts/run_tests.sh
```

Documentation: https://szaghi.github.io/HERALD. License: your choice of GPL-3.0-or-later, BSD-2-Clause,
BSD-3-Clause or MIT.
