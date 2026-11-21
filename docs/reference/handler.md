---
icon: ranks
---

# The handler

Module `herald_mpih_object`, type `mpih_object`.

## Components

| Component | Type | |
|---|---|---|
| `comm` | integer | communicator of the handler (default `HERALD_COMM_WORLD`) |
| `node_comm` | integer | communicator of the ranks sharing this node's memory, split from `comm` |
| `myrank`, `procs_number` | integer | rank in `comm`, ranks of `comm` |
| `node_myrank`, `node_procs_number` | integer | rank in `node_comm`, ranks of `node_comm` |
| `myrankstr` | character, allocatable | rank prefix of the messages, `[mpi-00000]` |
| `is_initialized` | logical | `initialize` ran |
| `owns_mpi` | logical | `initialize` initialized MPI, so `finalize` finalizes it |
| `error` | integer | error status of the last operation |
| `req_send_recv(0:2*procs_number-1)` | integer, allocatable | requests of the program's own sends and receives |
| `timer`, `memory`, `device` | objects | [timers](/reference/timers), [memory](/reference/memory), [devices](/reference/device) |
| `memory_avail` | real | host memory budget of the rank at `initialize`, GB |

## Life

```fortran
call mpih%initialize(comm, do_mpi_init, do_device_init, myrankstr_char_length, verbose, require_device)
call mpih%finalize(do_mpi_finalize)
```

| Argument | Default | |
|---|---|---|
| `comm` | all the ranks | communicator of the handler |
| `do_mpi_init` | `.true.` | initialize MPI if nobody has; `.false.` stops the run if MPI is not initialized |
| `do_device_init` | `.false.` | bind the rank to a [device](/reference/device) |
| `require_device` | `.false.` | stop if there is no device |
| `myrankstr_char_length` | 5 | digits of the rank in the prefix |
| `verbose` | `.false.` | print `description()` |
| `do_mpi_finalize` | `owns_mpi` | finalize MPI |

`initialize` is collective and once-only. `finalize` frees the node communicator and makes the handler
initializable again.

## Messages

| Method | |
|---|---|
| `print_message(msg, root_only)` | `msg` on the standard output with the prefix; `root_only=.true.`: rank 0 only |
| `warning(msg, root_only)` | `warning: msg` on the standard error with the prefix |
| `prefix()` | the prefix, empty before `initialize` |
| `description()` | ranks, node ranks, memory and device, one line each, every line prefixed |
| `is_root()` | true on rank 0 of `comm` |

## Fatal errors

| Method | |
|---|---|
| `error_stop(msg)` | print `error stop msg`, abort every rank, exit status 1 |
| `abort(error_code, msg)` | the same, with the caller's code for the launcher (default -101) |
| `check_memory(bytes_needed, what)` | `error_stop` if the bytes do not fit the [budget](/reference/memory) |

Both flush the standard output and error, wait 0.5 s for the launcher to forward them, then call `MPI_ABORT` on
`MPI_COMM_WORLD`. Without MPI (serial build, before `MPI_INIT`, after `MPI_FINALIZE`) the process stops alone.

## Barrier

`barrier()` blocks until every rank of `comm` has called it. `barrier(tictoc, timing, single)` also reads the clock,
as ADAM's and FUNDAL's did: see [timers](/reference/timers#the-timed-barrier).
