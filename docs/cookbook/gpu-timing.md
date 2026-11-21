---
icon: device
---

# Time a region on a GPU

A region that launches asynchronous device work returns before the work is done: timed as it is, it looks fast and
the next region looks slow. The clock must be read after the device queue is drained.

## With HERALD's device layer

Compile HERALD with `-DHERALD_OAC` and initialize with `do_device_init=.true.`: when a device is bound, the timers
wait for it at every `tic` and `toc` ([tutorial 6](/tutorial/06-device)). Nothing else to do.

## With a synchronization of your own

HERALD built with no device runtime knows no device. Register the procedure that drains the queue:

<<< @/examples/snippets/cookbook_timers-sync.F90{fortran}

<<< @/examples/snippets/cookbook_timers-register.F90{fortran}

The procedure is a module procedure (or an external one): a pointer to an internal procedure needs an executable
stack. `set_device_sync()` with no argument removes it.

<<< @/examples/output/cookbook-timers.txt{text}

The first line counts the two calls, one at `tic` and one at `toc`.
