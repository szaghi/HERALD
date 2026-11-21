---
icon: timers
---

# Find a mismatched tic/toc

A `toc` with no `tic`, a `tic` of a timer that is already running, a name misspelled once: the timers go on returning
plausible numbers. HERALD counts these misuses in place of printing from every rank:

<<< @/examples/snippets/cookbook_timers-misuse.F90{fortran}

| Counted | Where |
|---|---|
| a `toc` of a timer that is not running | that timer |
| a `tic` of a running timer (the interval restarts, its first part is lost) | that timer |
| a `toc` on another clock than the `tic` (across `MPI_INIT` or `MPI_FINALIZE`; the interval is discarded) | that timer |
| a `toc` of a name never started | the unknown stops |

`timer%misuses()` is the total on this rank. The report adds one line per timer with misuses, summed over the ranks,
and the CSV has a `misuses` column:

<<< @/examples/output/cookbook-timers.txt{text}

A test suite can assert `mpih%timer%misuses() == 0` at the end of a run.
