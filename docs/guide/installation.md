# Installation

HERALD has no dependencies: a Fortran compiler and, for the MPI builds, the MPI whose wrapper (`mpif90`) is first on
`PATH`.

## FoBiS

```bash
git clone https://github.com/szaghi/HERALD && cd HERALD
fobis build --mode static-gnu    # lib/gnu/static/libherald.a and lib/gnu/static/mod/
```

| You want | Mode |
|---|---|
| the MPI library, gfortran / nvfortran / ifx | `static-gnu`, `static-nvf`, `static-intel` (`shared-*`: shared) |
| no MPI at all (one rank) | `static-gnu-serial`, `static-nvf-serial`, `static-intel-serial` |
| the OpenACC device layer, nvfortran | `static-nvf-oac` (`--varset cc80\|cc89\|cc90\|iac`: the compute capability) |

Every mode: [Build](/reference/build).

## Use it

```bash
mpif90 -I lib/gnu/static/mod my_program.F90 lib/gnu/static/libherald.a -o my_program
```

A program that uses the OpenACC device layer is compiled and linked with the same `-acc -gpu=` flags as the library.

## As a FoBiS dependency

```ini
[dependencies]
deps_dir = src/third_party
HERALD   = https://github.com/szaghi/HERALD :: branch=main
```

`fobis fetch` clones it; add `HERALD/src/tests/ HERALD/docs/ HERALD/scripts/` to the mode's `exclude_dirs`, and
`-DHERALD_NO_MPI`, `-DHERALD_OAC` or `-DHERALD_OMP` to its `preproc` as the build needs.

## fpm

```toml
[dependencies]
HERALD = { git = "https://github.com/szaghi/HERALD", branch = "main" }
```

fpm builds the serial library (`HERALD_NO_MPI`); the MPI and device builds are the FoBiS modes.

## The one-line installer

```bash
curl -fsSL https://github.com/szaghi/HERALD/releases/latest/download/install.sh | bash -s -- --prefix ~/.local
```

Available from the first release. It builds the serial library: an MPI library must be built against the site's own
MPI, with the modes above.

## Tests

```bash
fobis build --mode tests-gnu && bash scripts/run_tests.sh    # MPI tests on 2 ranks (--np N)
```

The programs and where they run: [Test programs](/reference/tests).
