# Test programs

Every program of `src/tests/`; `scripts/run_tests.sh` runs those whose name holds `mpi` under `mpirun` (2 ranks by
default) and expects a non-zero exit status from those whose name holds `_xfail_`.

| Program | Checks |
|---|---|
| `herald_test_kinds` | the widths of the library's kinds |
| `herald_test_strings` | numbers to strings |
| `herald_test_toolchain_mpi` | the MPI of the build mode, without the handler |
| `herald_test_core_mpi` | `initialize` once, ranks, node ranks, prefix, description, `finalize` |
| `herald_test_comm_mpi` | a handler on a communicator of the program; MPI left alive by a handler that did not start it |
| `herald_test_error_stop_xfail_mpi` | an error on one rank stops every rank, non-zero |
| `herald_test_timers_mpi` | named timers against known sleeps, statistics, CPU/wall, misuses, CSV, device synchronization, timed barriers |
| `herald_test_timer_clock_mpi` | an interval across `MPI_INIT` is discarded |
| `herald_test_memory_readers` | the readers of `/proc` and of cgroup v1 and v2 limits, on files written by the test |
| `herald_test_memory_mpi` | the budget, the use and the peak on the machine that runs the test |
| `herald_test_memory_budget_xfail_mpi` | more than the budget stops the run |
| `herald_test_device_mpi` | the binding, the sharers and the memory share, on the host or on devices |
| `herald_test_require_device_xfail_mpi` | a required device that is not there stops the run |

The documentation examples of `docs/examples/src/` are compiled and run too, by `scripts/docs_examples.sh`, and their
outputs compared with the committed ones.

## Where they run

| | gfortran | nvfortran | ifx |
|---|---|---|---|
| MPI, optimised | CI | CI | CI |
| serial | CI (fpm) | local | - |
| OpenMP device layer | CI (host branch) | - | - |
| OpenACC device layer | - | CI (host branch); on GPUs locally | - |
