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
`libherald_serial.a`).

## fpm

```toml
[dependencies]
HERALD = { git = "https://github.com/szaghi/HERALD", branch = "main" }
```

fpm builds the serial library; the MPI builds are the fobos modes.
