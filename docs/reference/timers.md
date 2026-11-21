---
icon: timers
---

# Timers

Module `herald_timer_object`, type `timer_object`; the handler's are `mpih%timer`.

## On the handler

| Method | |
|---|---|
| `tic(name, sync)` | start the timer `name` (created at its first start); without `name`, the anonymous timer `tic-toc` |
| `toc(name, sync)` | stop it; returns the seconds of the interval, 0 if it was not running |

`sync=.true.` calls a barrier on `comm` before the clock is read (collective).

## On `mpih%timer`

| Method | Collective | |
|---|---|---|
| `start(name, sync)`, `stop(name, sync)` | with `sync` | what `tic` and `toc` call |
| `elapsed(name)`, `elapsed_cpu(name)` | no | accumulated wall and CPU seconds on this rank; 0 for an unknown name |
| `index_of(name)` | no | index of the timer, 0 if none |
| `reset(name)` | no | zero one timer, or all without `name` |
| `misuses()` | no | [misuses](/cookbook/misuse) on this rank |
| `set_device_sync(device_sync)` | no | register, or remove, the [device synchronization](/cookbook/gpu-timing) |
| `is_consistent()` | yes | every rank has the same timers in the same order |
| `statistics(...)` | yes | the reductions over the ranks |
| `report(unit, csv)` | yes | print the table, or the CSV, on rank 0 |
| `report_string()`, `report_csv_string()` | yes | the same as strings, equal on every rank |

Per timer, indexed by `index_of`: `name`, `calls`, `total`, `last`, `cpu_total`, `misuse`, `is_running`.

## `statistics`

```fortran
call mpih%timer%statistics(t_min, t_mean, t_max, is_consistent, calls, per_call, cpu_wall, misuse, unknown_stops)
```

| Argument | |
|---|---|
| `t_min`, `t_mean`, `t_max` | minimum, mean and maximum over the ranks of each timer's total seconds |
| `is_consistent` | every rank has the same timers; if false, everything holds this rank's values |
| `calls` | calls of all the ranks |
| `per_call` | seconds of all the ranks over their calls |
| `cpu_wall` | CPU seconds of all the ranks over their wall seconds |
| `misuse`, `unknown_stops` | misuses of all the ranks |

The first three are required; all the arrays are allocated by the call, one element per timer.

## The clocks

| | |
|---|---|
| Wall | `MPI_WTIME` while MPI is active, `system_clock` otherwise; an interval across the two is discarded |
| CPU | the process' CPU time, all its threads (POSIX `CLOCK_PROCESS_CPUTIME_ID`), not the intrinsic `cpu_time`, which nvfortran answers with the wall clock |

CPU/wall is near 1 for a rank that computes, below for one that sleeps or waits for a device, above with threads. A
rank waiting inside MPI may still show about 1: MPI libraries poll.

## Limits

- Names are looked up by linear search and cut at 48 characters (`TIMER_NAME_LEN`): tens of timers around whole
  phases, not timers inside hot loops.
- The reductions pair the timers by index: ranks that create different timers, or in a different order, are
  reported as inconsistent.

## The timed barrier

`barrier(tictoc=.true.)` reads the clock after the barrier into the two slots of `timing(1:2)` in turn;
`tictoc_timing()` returns their difference; `timing=` returns the clock read; `single=.true.` does not advance to
the other slot. Kept for the clients of ADAM's and FUNDAL's handlers; new code uses `tic(name, sync=.true.)`.
