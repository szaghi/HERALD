# About

HERALD (**H**PC **E**nvironment, **R**anks, **A**ccounting, **L**ogging, **D**evices) is the MPI handler of HPC
codes: the one object a program declares to know where it runs and to speak for its ranks.

- **Environment**: the communicator and the node-local (shared-memory) communicator.
- **Ranks**: the rank and the number of ranks, of the run and of the node.
- **Accounting**: named timers, and the memory budget of each rank.
- **Logging**: rank-prefixed messages, and a fatal path that stops every rank.
- **Devices**: the binding of the node's ranks to its devices.

It replaces the `mpih_object` classes that ADAM and FUNDAL each carried, two copies of one idea that had drifted
apart. HERALD has no dependencies: MPI, the compiler and Linux (the memory queries read `/proc` and the cgroup
files). Built with `-DHERALD_NO_MPI` it is a single-rank stub with the same interface.

## Status

The handler is written and tested on the host with gfortran and nvfortran, with and without MPI. Its device layer
(OpenACC) is compiled and tested on the host device type only: it has not run on a GPU yet. Not released.
