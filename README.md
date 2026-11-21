<div align="center">

# HERALD

#### *The MPI handler of HPC codes: one object that knows where the program runs and speaks for its ranks*

### **H**PC **E**nvironment, **R**anks, **A**ccounting, **L**ogging, **D**evices

> Ranks and node topology, named timers reduced over the ranks, the memory budget of a rank, messages with the rank
> prefix, a fatal path that stops every rank, and the binding of ranks to devices, in modern Fortran with no
> dependencies. It replaces the `mpih_object` classes that ADAM and FUNDAL each carried.

[![CI](https://github.com/szaghi/HERALD/actions/workflows/ci.yml/badge.svg)](https://github.com/szaghi/HERALD/actions/workflows/ci.yml)
[![Matrix](https://github.com/szaghi/HERALD/actions/workflows/matrix.yml/badge.svg)](https://github.com/szaghi/HERALD/actions/workflows/matrix.yml)
[![Docs examples](https://github.com/szaghi/HERALD/actions/workflows/docs-examples.yml/badge.svg)](https://github.com/szaghi/HERALD/actions/workflows/docs-examples.yml)
[![Fortran](https://img.shields.io/badge/Fortran-modern-734f96?logo=fortran&logoColor=white)](https://fortran-lang.org)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue)](LICENSE.gpl3.md)
[![License: BSD-2](https://img.shields.io/badge/license-BSD--2--Clause-blue)](LICENSE.bsd-2.md)
[![License: BSD-3](https://img.shields.io/badge/license-BSD--3--Clause-blue)](LICENSE.bsd-3.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE.mit.md)

<div>
<table>
<tr>
<td><b>🧭 One handler, declared once</b><br><sub>The communicator, the rank, the ranks of the run and of the node. <code>initialize</code> is once-only whoever calls it, takes any communicator, starts MPI on demand and lets who started it finalize it. <a href="https://szaghi.github.io/HERALD/tutorial/01-ranks">Tutorial 1</a></sub></td>
<td><b>🛑 An error stops every rank</b><br><sub><code>error_stop</code> on one rank ends the whole run with its message and exit status 1, instead of leaving the others waiting in a collective until the time limit. <a href="https://szaghi.github.io/HERALD/tutorial/02-errors">Tutorial 2</a></sub></td>
</tr>
<tr>
<td><b>⏱️ Timers reduced over the ranks</b><br><sub>Named, accumulating timers; minimum, mean and maximum over the ranks, load imbalance, seconds per call and CPU over wall time, as a table or as CSV; mismatched tic/toc are counted. <a href="https://szaghi.github.io/HERALD/tutorial/03-timers">Tutorial 3</a></sub></td>
<td><b>🧮 The memory budget of a rank</b><br><sub>The node's memory or the job's cgroup limit (Slurm <code>--mem</code>), whichever binds, divided by the ranks on the node; the memory in use and its peak; a readable error before an allocation that does not fit. <a href="https://szaghi.github.io/HERALD/tutorial/04-memory">Tutorial 4</a></sub></td>
</tr>
<tr>
<td><b>🎛️ The device of a rank</b><br><sub>Ranks bound to the devices of their node in turn, the ranks sharing each device and its memory share, on OpenACC or OpenMP; the timers wait for the device before reading the clock. <a href="https://szaghi.github.io/HERALD/tutorial/06-device">Tutorial 6</a></sub></td>
<td><b>🧰 No dependencies, three compilers</b><br><sub>MPI, the compiler and Linux. Built without MPI it is a single-rank library with the same interface. Tested with gfortran, nvfortran and ifx; built with FoBiS or fpm. <a href="https://szaghi.github.io/HERALD/guide/installation">Installation</a></sub></td>
</tr>
</table>
</div>

**[Full documentation](https://szaghi.github.io/HERALD/)**: [start](https://szaghi.github.io/HERALD/guide/) · [tutorial](https://szaghi.github.io/HERALD/tutorial/) · [cookbook](https://szaghi.github.io/HERALD/cookbook/) · [reference](https://szaghi.github.io/HERALD/reference/) · [API](https://szaghi.github.io/HERALD/api/)

</div>

---

## Quick start

```bash
git clone https://github.com/szaghi/HERALD && cd HERALD
fobis build --mode static-gnu                                 # lib/gnu/static/libherald.a
fobis build --mode tests-gnu && bash scripts/run_tests.sh     # the test programs, MPI ones on 2 ranks
```

as a FoBiS dependency, in the `fobos` of your project (then `fobis fetch && fobis build`):

```ini
[dependencies]
deps_dir = src/third_party
HERALD   = https://github.com/szaghi/HERALD :: branch=main
```

or as an fpm dependency, in your `fpm.toml` (the serial library: one rank, no MPI):

```toml
[dependencies]
HERALD = { git = "https://github.com/szaghi/HERALD", branch = "main" }
```

One handler, initialized once:

```fortran
use herald
type(mpih_object) :: mpih

call mpih%initialize                                          ! MPI too, if nobody has initialized it
call mpih%check_memory(bytes_needed=8*n, what='the field')    ! stop every rank if it does not fit the budget
call mpih%tic(name='solve', sync=.true.)                      ! a named timer
call solve
seconds = mpih%toc(name='solve')
if (failed) call mpih%error_stop(msg='the solver diverged')   ! stops every rank, exit status 1
call mpih%timer%report                                        ! min, mean, max over the ranks, by rank 0
call mpih%finalize                                            ! MPI too, if the handler initialized it
```

The [tutorial](https://szaghi.github.io/HERALD/tutorial/) goes from the first message to the device of a rank; the
[reference](https://szaghi.github.io/HERALD/reference/) lists every component and method. Coming from ADAM's or
FUNDAL's handler: [what changes](https://szaghi.github.io/HERALD/guide/migration).

## Status

Not released yet. The device memory query of AMD's HIP runtime (`-DHERALD_HIP`) is written and not compiled by any
build mode.

## Authors

**[Stefano Zaghi](https://github.com/szaghi)** · stefano.zaghi@gmail.com

## License

HERALD is available under your choice of license:

| License | SPDX | File |
|---|---|---|
| GNU General Public License v3 | `GPL-3.0-or-later` | [LICENSE.gpl3.md](LICENSE.gpl3.md) |
| BSD 2-Clause | `BSD-2-Clause` | [LICENSE.bsd-2.md](LICENSE.bsd-2.md) |
| BSD 3-Clause | `BSD-3-Clause` | [LICENSE.bsd-3.md](LICENSE.bsd-3.md) |
| MIT | `MIT` | [LICENSE.mit.md](LICENSE.mit.md) |

© [Stefano Zaghi](https://github.com/szaghi)
