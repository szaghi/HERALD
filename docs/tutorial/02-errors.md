---
title: 2. Errors
---

# 2. Errors

A parallel program fails on one rank at a time: a check that only that rank evaluates. The others must not go on
waiting for it.

## A rank-local error

<<< @/examples/snippets/t02_errors-check.F90{fortran}

Only rank 1 calls `error_stop`. Meanwhile rank 0 is here:

<<< @/examples/snippets/t02_errors-wait.F90{fortran}

A handler that answered the error with `MPI_FINALIZE` would leave rank 1 waiting for rank 0 to finalize and rank 0
waiting in the barrier: a job that hangs until its time limit. `error_stop` aborts every rank.

## Running it

<<< @/examples/output/t02_errors.txt{text}

The launcher adds its own lines about the abort, which change with the MPI library: they are filtered out here. The
exit status is what a script or a scheduler sees:

<<< @/examples/output/t02_status.txt{text}

## `abort`

`abort(error_code, msg)` does the same with an error code of the caller for the launcher (default -101); the exit
status of the process is 1 in any case.

::: tip What you learned
`error_stop` ends the run, on every rank, with a non-zero exit status. Reference:
[the handler](/reference/handler#fatal-errors).
:::
