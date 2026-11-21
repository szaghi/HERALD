# From ADAM's or FUNDAL's handler

The class keeps its name, `mpih_object`. `initialize`, `finalize`, `print_message`, `error_stop`, `abort`, `barrier`,
`tic`, `toc`, `tictoc_timing`, `myrank`, `myrankstr`, `procs_number`, `error` and `req_send_recv` keep their meaning.

## What changes

| Was | Is |
|---|---|
| `use adam_mpih_object` / `use fundal_mpih_object` | `use herald` |
| `MPI_COMM_WORLD` always | `initialize(comm=)`, default all the ranks |
| `finalize` always finalized MPI | only if the handler initialized it; else `finalize(do_mpi_finalize=.true.)` |
| FUNDAL: `error_stop` called `MPI_FINALIZE` (a rank-local error hung the run) | `MPI_ABORT`, exit status 1 |
| FUNDAL: `initialize` was `intent(out)` and needed an outer guard | once-only |
| `abort` ended with a plain `stop` | exit status 1 |
| `toc()` on the single anonymous slot | the same, plus named timers: `tic(name=)`, `toc(name=)` |

## Names of FUNDAL's device data

| FUNDAL | HERALD |
|---|---|
| `devs_number` | `device%devices_number` |
| `mydev` | `device%mydev` (-1 on the host, not 0) |
| `myhos` | `device%myhos` |
| `devtype` | `device%devtype` |
| `dev_memory_total` | `device%memory_total` |
| `dev_memory_avail` | `device%memory_free` |
| `local_comm` | `node_comm` |
| `hos_memory_avail` | `memory%per_rank()` (bytes) or `memory_avail` (GB) |

FUNDAL's host-fallback policy is kept: with no device the run continues on the host with one warning, and stops if a
device is required by `require_device=.true.`, by `ACC_DEVICE_TYPE` naming a device type or by
`OMP_TARGET_OFFLOAD=MANDATORY`.

## Names of ADAM's data

| ADAM | HERALD |
|---|---|
| `memory_avail` (GB per rank) | `memory_avail`, or `memory%per_rank()` in bytes |
| `node_comm`, `node_procs_number` | the same |
| `has_node_comm` | gone: `initialize` is once-only |
| `mpih_fnl_device_sharers` | `device%sharers` |
| `mpih_nvf_object` (CUDA Fortran) | not in HERALD |
