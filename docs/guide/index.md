# About

HERALD (**H**PC **E**nvironment, **R**anks, **A**ccounting, **L**ogging, **D**evices) is the MPI handler of HPC
codes: the one object a program declares to know where it runs and to speak for its ranks.

| Letter | What the handler gives |
|---|---|
| **E**nvironment | the communicator, the node-local communicator, MPI initialized on demand and finalized by who initialized it |
| **R**anks | the rank and the number of ranks, of the run and of the node |
| **A**ccounting | named timers reduced over the ranks; the memory budget of a rank and the memory it uses |
| **L**ogging | messages with the rank prefix; a fatal path that stops every rank with a non-zero exit status |
| **D**evices | the device of each rank, the ranks that share it and its memory |

It replaces the `mpih_object` classes that ADAM and FUNDAL each carried, two copies of one idea that had drifted
apart: one fixed defects the other still had. The class keeps their name, so a client changes its `use` statement and
[little else](/guide/migration).

## What it depends on

Nothing but MPI, the compiler and Linux. The device layer uses the compiler's own runtime (OpenACC or OpenMP), chosen
when HERALD is compiled; the memory queries read `/proc` and the cgroup files. Built with `-DHERALD_NO_MPI` there is
no MPI library at all: one rank, the same interface.

## Where to go

- [Quick start](/guide/quickstart): a program in twenty lines.
- [Tutorial](/tutorial/): six chapters, from the first message to the device of a rank.
- [Cookbook](/cookbook/): recipes for one task each.
- [Reference](/reference/): every component and method, the build macros and modes.
- [API](/api/): the pages generated from the sources.

## Status

Not released yet. The handler is tested with gfortran, nvfortran and ifx, with and without MPI; the OpenACC device
layer has run on NVIDIA GPUs with nvfortran, the OpenMP one with gfortran. The device memory query of AMD's HIP
runtime (`-DHERALD_HIP`) is written and not compiled by any mode.
