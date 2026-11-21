# Installation

HERALD has no dependencies: a Fortran compiler and, for the MPI modes, the MPI whose wrapper (`mpif90`) is first on
`PATH`.

## FoBiS

```bash
git clone https://github.com/szaghi/HERALD && cd HERALD
fobis build --mode static-gnu    # lib/gnu/static/libherald.a (shared-gnu: libherald.so)
```

`fobis build --lmodes` lists the modes: static and shared MPI libraries and tests for gfortran (`-gnu`), nvfortran
(`-nvf`) and ifx (`-intel`), and the serial twins (`-serial`, `-DHERALD_NO_MPI`: no MPI library, one rank,
`libherald_serial.a`). `static-nvf-oac` and `tests-nvf-oac` add the OpenACC device layer (`-DHERALD_OAC`;
`--varset cc80|cc89|cc90|iac` picks the compute capability, cc89 by default); `tests-gnu-omp` builds the OpenMP target layer (`-DHERALD_OMP`; `-DHERALD_HIP` adds the device
memory query of AMD's HIP runtime).

## fpm

```toml
[dependencies]
HERALD = { git = "https://github.com/szaghi/HERALD", branch = "main" }
```

fpm builds the serial library; the MPI builds are the fobos modes.
