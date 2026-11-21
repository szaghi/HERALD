# Quick start

Build the library ([Installation](/guide/installation)), then one handler, initialized once:

<<< @/examples/snippets/quickstart.F90{fortran}

<<< @/examples/output/quickstart.txt{text}

## Line by line

<<< @/examples/snippets/quickstart-use.F90{fortran}

`use herald` gives the class `mpih_object` and nothing that can clash with a kinds library: HERALD's own kinds are not
exported, so the program brings its own.

<<< @/examples/snippets/quickstart-handler.F90{fortran}

The library exports the class, not an instance: the program owns its handler, and may have
[more than one](/tutorial/05-communicator).

<<< @/examples/snippets/quickstart-body.F90{fortran}

- `initialize` initializes MPI if nobody has, and then `finalize` finalizes it; a second `initialize` returns at once.
- `check_memory` compares the bytes with the [budget of the rank](/tutorial/04-memory).
- `tic` and `toc` are a [named timer](/tutorial/03-timers); `toc` returns the seconds of the interval.
- `error_stop` [stops every rank](/tutorial/02-errors), not only the one that calls it.
- `print_message` prefixes the rank; `root_only=.true.` prints on rank 0 alone.

## Compile and run

```bash
mpif90 -I lib/gnu/static/mod quickstart.F90 lib/gnu/static/libherald.a -o quickstart
mpirun -np 2 ./quickstart
```
