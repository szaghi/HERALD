# Build without MPI

Compiled with `-DHERALD_NO_MPI`, HERALD uses no MPI library: one rank, rank 0, and the same interface. A program
keeps its `mpih%` calls and builds for a laptop or a test runner with no MPI installed.

```bash
fobis build --mode static-gnu-serial      # lib/gnu/static-serial/libherald_serial.a
gfortran -I lib/gnu/static-serial/mod my_program.F90 lib/gnu/static-serial/libherald_serial.a
```

| In a serial build | |
|---|---|
| `HERALD_HAS_MPI` | `.false.` |
| `procs_number`, `node_procs_number` | 1 |
| `barrier`, `sync=.true.` | return at once |
| the reductions of the reports | this rank's values |
| `error_stop` | stops the process, exit status 1 |
| the clock | `system_clock` |

The program's own MPI calls still need a guard of its own: HERALD stands in for the handler, not for MPI.

fpm builds the serial library: `fpm.toml` defines `HERALD_NO_MPI`.
