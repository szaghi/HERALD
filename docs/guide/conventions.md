# Conventions

The rules every page assumes.

## One handler, initialized once

`initialize` is once-only: every layer of a program (the application, a library, a test driver) can call it, and only
the first call works. `finalize` makes the handler initializable again. A handler that is not initialized still
prints (with no prefix) and still stops the run.

## Who initializes MPI finalizes it

`initialize` calls `MPI_INIT` only if MPI is not initialized, and remembers it (`owns_mpi`); `finalize` then calls
`MPI_FINALIZE`. A program that [initializes MPI itself](/cookbook/own-mpi) finalizes it itself.

`MPI_INIT` runs with the IEEE halting modes off, restored afterwards: Open MPI raises an invalid operation inside it,
and a program compiled with floating-point traps (`gfortran -ffpe-trap=invalid`) would die there.

## Collective calls

Some methods talk to the other ranks: **every rank of the communicator must call them**, in the same order, or the
run hangs.

| Collective | Not collective |
|---|---|
| `initialize`, `barrier`, `tic`/`toc` with `sync=.true.` | `tic`/`toc`, `timer%start`/`stop`, `timer%elapsed` |
| `timer%statistics`, `timer%report`, `timer%report_string`, `timer%report_csv_string`, `timer%is_consistent` | `timer%misuses`, `timer%reset` |
| `memory%report`, `memory%report_string` | `memory%per_rank`, `memory%used`, `memory%peak`, `memory%check`, `check_memory` |
| `device%initialize` | `print_message`, `warning`, `error_stop`, `abort` |

A report prints on rank 0 only, but every rank calls it.

## Sizes are bytes, times are seconds

Every size is a 64-bit integer number of bytes, -1 when unknown; `memory_avail` alone is in GB, the unit ADAM's
clients read. Every time is a double-precision number of seconds.

## Kinds

HERALD's kinds (`I4P`, `I8P`, `R8P`, from `iso_fortran_env`) are its own: `use herald` does not export them. A client
uses `int32`, `int64` and `real64`, or PENF's kinds of the same names, with no ambiguity.

## Fatal means every rank

`error_stop` and `abort` flush the output, wait half a second for the launcher to forward it, call `MPI_ABORT` on
`MPI_COMM_WORLD` and stop with exit status 1. A check that only one rank evaluates therefore ends the whole run.

## One clock per interval

The clock is `MPI_WTIME` while MPI is active and `system_clock` otherwise. An interval that starts on one and ends on
the other (across `MPI_INIT` or `MPI_FINALIZE`) is discarded and counted as a [misuse](/cookbook/misuse).
