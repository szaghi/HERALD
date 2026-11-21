# A program that initializes MPI itself

Who initializes MPI finalizes it. When the program, or a library called before HERALD, calls `MPI_INIT`, the handler
finds MPI running and leaves it running at `finalize`:

<<< @/examples/snippets/cookbook_own_mpi-own.F90{fortran}

<<< @/examples/output/cookbook-own-mpi.txt{text}

- `do_mpi_init=.false.` is a statement, not a need: without it `initialize` would also find MPI running. With it,
  the run stops if MPI is not initialized, which catches a wrong call order.
- `finalize(do_mpi_finalize=.true.)` finalizes MPI on request.

::: warning Floating-point traps
A program compiled with `gfortran -ffpe-trap=invalid` dies of SIGFPE inside a bare `MPI_INIT` of Open MPI 5. Let
HERALD initialize MPI (it masks the traps around the call), or mask them yourself with `ieee_set_halting_mode`.
:::
