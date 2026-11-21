---
layout: home

hero:
  name: HERALD
  text: HPC Environment, Ranks, Accounting, Logging, Devices
  tagline: The MPI handler of HPC codes, in modern Fortran
  actions:
    - theme: brand
      text: Start
      link: /guide/
    - theme: alt
      text: Tutorial
      link: /tutorial/
    - theme: alt
      text: Cookbook
      link: /cookbook/
    - theme: alt
      text: Reference
      link: /reference/
    - theme: alt
      text: API
      link: /api/

features:
  - title: One handler, declared once
    details: The communicator, the rank, the ranks of the run and of the node. Initialized once whoever calls it, on any communicator; MPI started on demand and finalized by who started it.
    link: /tutorial/01-ranks
  - title: An error stops every rank
    details: A check that one rank alone evaluates ends the whole run, with its message and a non-zero exit status, instead of leaving the others waiting until the time limit.
    link: /tutorial/02-errors
  - title: Timers reduced over the ranks
    details: Named, accumulating timers; minimum, mean and maximum over the ranks, load imbalance, seconds per call, CPU over wall time, as a table or as CSV. Mismatched tic/toc are counted.
    link: /tutorial/03-timers
  - title: The memory budget of a rank
    details: The node's memory or the cgroup limit of the job, whichever binds, divided by the ranks on the node; the memory in use and its peak; a readable error before an allocation that does not fit.
    link: /tutorial/04-memory
  - title: The device of a rank
    details: Ranks bound to the devices of their node in turn, the ranks sharing each device and its memory share, on OpenACC or OpenMP; the timers wait for the device.
    link: /tutorial/06-device
  - title: No dependencies
    details: MPI, the compiler and Linux. Without MPI, a single-rank build with the same interface. Tested with gfortran, nvfortran and ifx; built with FoBiS or fpm.
    link: /guide/installation
---
