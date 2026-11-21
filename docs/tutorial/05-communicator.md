---
title: 5. A communicator of your own
icon: ranks
---

# 5. A communicator of your own

A handler is not tied to all the ranks: it takes any communicator, and a program can have several handlers.

## The world, then a half

<<< @/examples/snippets/t05_comm-world.F90{fortran}

<<< @/examples/snippets/t05_comm-split.F90{fortran}

`world` initialized MPI and owns it. `half` finds MPI running: its rank, its ranks, its node communicator and its
timers are those of the half.

<<< @/examples/snippets/t05_comm-timers.F90{fortran}

## Finalize in order

<<< @/examples/snippets/t05_comm-finalize.F90{fortran}

## Running it

<<< @/examples/output/t05_comm.txt{text}

::: tip What you learned
`initialize(comm=)`; only the handler that initialized MPI finalizes it. Recipe:
[a program that initializes MPI itself](/cookbook/own-mpi).
:::
