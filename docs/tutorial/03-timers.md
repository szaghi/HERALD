---
title: 3. Timers
icon: timers
---

# 3. Timers

## A named timer

<<< @/examples/snippets/t03_timers-loop.F90{fortran}

The timer `solve` is created by its first `tic`. Each `tic`/`toc` pair adds its interval to the timer's total and
counts one call; `toc` returns the seconds of the interval. `sync=.true.` adds a barrier before the clock is read,
so that every rank starts together: use it for timings that must be compared, not everywhere, since a barrier in
every timed region changes what is measured.

## Over the ranks

<<< @/examples/snippets/t03_timers-statistics.F90{fortran}

<HeraldIcon name="imbalance" :size="40" label="load imbalance" float />

`statistics` reduces the timers over the ranks. The ratio maximum/mean is the load imbalance of the region; the
ratio CPU/wall tells computing (near 1) from waiting (near 0: here the ranks sleep).

<<< @/examples/output/t03_timers.txt{text}

## The report

<<< @/examples/snippets/t03_timers-report.F90{fortran}

<HeraldIcon name="report" :size="40" label="table and CSV report" float />

`report` prints the same reductions as a table, on rank 0. Its numbers change from run to run; this one was captured
by hand:

<<< @/examples/device/t03_report.txt{text}

## For a program to read

<<< @/examples/snippets/t03_timers-csv.F90{fortran}

`report_csv_string` gives the table as CSV; its first line tells whether every rank had the same timers. The
[cookbook](/cookbook/csv) writes it to a file.

::: tip What you learned
`tic(name)` and `toc(name)` accumulate; `timer%report` reduces over the ranks. Reference: [timers](/reference/timers).
:::
