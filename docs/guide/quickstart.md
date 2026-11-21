# Quick Start

A program declares one handler and initializes it once. This is `src/tests/herald_test_quickstart_mpi.F90`, compiled
and run by the test suite:

```fortran
program quickstart
use, intrinsic :: iso_fortran_env, only : int64, real64
use            :: herald
implicit none
type(mpih_object)         :: mpih      !< The MPI handler of the program.
real(real64), allocatable :: field(:)  !< Some work to time.
real(real64)              :: seconds   !< Seconds of the last interval.
integer(int64), parameter :: N=2000000 !< Elements of the field.

call mpih%initialize(do_device_init=.true.)                  ! MPI too, if nobody has initialized it
call mpih%check_memory(bytes_needed=8*N, what='the field')   ! stop every rank, with the numbers, if it does not fit
allocate(field(N))
call mpih%tic(name='fill', sync=.true.)                      ! a named timer; sync: every rank starts together
call random_number(field)
seconds = mpih%toc(name='fill')
if (sum(field) < 0._real64 .or. seconds < 0._real64) call mpih%error_stop(msg='impossible') ! stops every rank, status 1
if (mpih%is_root()) print '(A)', mpih%description()         ! ranks, node, memory budget, device
call mpih%timer%report                                       ! min, mean, max over the ranks, printed by rank 0
call mpih%memory%report                                      ! in use, peak and budget over the ranks
call mpih%print_message('done', root_only=.true.)
call mpih%finalize                                           ! MPI too, if the handler initialized it
endprogram quickstart
```

`use herald` gives the class `mpih_object` and nothing that can clash with a kinds library: HERALD's own kinds are not
exported.

## What the handler holds

| Component or method | What it is |
|---|---|
| `comm`, `myrank`, `procs_number` | the communicator (any, not only `MPI_COMM_WORLD`), the rank and the ranks |
| `node_comm`, `node_myrank`, `node_procs_number` | the ranks that share this node's memory |
| `print_message`, `warning` | messages with the rank prefix, `root_only=.true.` for rank 0 alone |
| `error_stop`, `abort` | stop **every** rank, exit status 1 |
| `tic`, `toc`, `timer%report` | named accumulating timers, reduced over the ranks |
| `memory%per_rank()`, `memory%used()`, `memory%peak()`, `check_memory` | the memory budget of the rank and its use, bytes |
| `device%mydev`, `device%sharers`, `device%per_sharer()` | the device of the rank, the ranks sharing it, its memory share |

## From ADAM's or FUNDAL's handler

The type keeps its name, `mpih_object`, and `initialize`, `finalize`, `print_message`, `error_stop`, `abort`, `barrier`,
`tic`, `toc`, `tictoc_timing`, `myrank`, `myrankstr`, `procs_number` and `memory_avail` keep their meaning. What changes:

- `finalize` ends MPI only if the handler initialized it; a program that calls `MPI_INIT` itself passes
  `do_mpi_finalize=.true.` or calls `MPI_FINALIZE` itself;
- the device data are in `mpih%device`; FUNDAL's names map as `devs_number` → `device%devices_number`, `mydev` →
  `device%mydev`, `myhos` → `device%myhos`, `devtype` → `device%devtype`, `dev_memory_total` → `device%memory_total`,
  `dev_memory_avail` → `device%memory_free`, `local_comm` → `node_comm`, `hos_memory_avail` → `memory%per_rank()`
  (bytes) or `memory_avail` (GB);
- FUNDAL's host-fallback policy is kept: with no device the run continues on the host with one warning, and stops if
  a device is required by `require_device=.true.`, `ACC_DEVICE_TYPE` or `OMP_TARGET_OFFLOAD=MANDATORY`.

## Tests

```bash
fobis build --mode tests-gnu && bash scripts/run_tests.sh          # MPI tests on 2 ranks (--np N)
fobis clean --mode tests-gnu-serial
fobis build --mode tests-gnu-serial && bash scripts/run_tests.sh   # no MPI library
fobis rule --ex makecoverage-analysis   # what CI runs: coverage into docs/public/coverage.json
```

`exe/` is shared by the test modes: clean before switching mode or compiler. `tests-nvf-oac` builds the OpenACC device
layer into `exe-oac/`, `tests-gnu-omp` the OpenMP target one into `exe-omp/` (`bash scripts/run_tests.sh --exe-dir exe-omp`).
