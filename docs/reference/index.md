# Reference

## The handler at a glance

`type(mpih_object) :: mpih`, from `use herald`.

| | Components | Methods |
|---|---|---|
| [Handler](/reference/handler) | `comm`, `node_comm`, `myrank`, `procs_number`, `node_myrank`, `node_procs_number`, `myrankstr`, `is_initialized`, `owns_mpi`, `error`, `req_send_recv` | `initialize`, `finalize`, `is_root`, `prefix`, `description`, `print_message`, `warning`, `error_stop`, `abort`, `barrier` |
| [Timers](/reference/timers) | `timer` | `tic`, `toc`, `tictoc_timing`, `timer%start`, `timer%stop`, `timer%statistics`, `timer%report` ... |
| [Memory](/reference/memory) | `memory`, `memory_avail` | `check_memory`, `memory%per_rank`, `memory%used`, `memory%peak`, `memory%check`, `memory%report` ... |
| [Devices](/reference/device) | `device` | `device%per_sharer`, `device%sync` ... |

## What `use herald` exports

| Name | Kind | |
|---|---|---|
| `mpih_object` | type | the handler |
| `timer_object`, `memory_object`, `device_object` | types | the classes of its components, usable on their own |
| `device_sync_interface` | abstract interface | of a device synchronization procedure |
| `HERALD_HAS_MPI` | logical constant | the library is built with MPI |
| `HERALD_COMM_WORLD`, `HERALD_COMM_NULL` | integer constants | `MPI_COMM_WORLD` and `MPI_COMM_NULL`, or their stand-ins without MPI |
| `HERALD_DEVICE_RUNTIME` | character constant | `openacc`, `openmp` or `none` |
| `HERALD_DEVICE_HOST` | integer constant | the device type of the host |

Nothing else: no kinds, no instance of the handler.

## Elsewhere

- [Build: macros and modes](/reference/build)
- [Test programs](/reference/tests)
- [API](/api/): every module, type and procedure, generated from the sources.
