---
layout: home

hero:
  name: HERALD
  text: HPC Environment, Ranks, Accounting, Logging, Devices
  tagline: The MPI handler of HPC codes, in modern Fortran
  actions:
    - theme: brand
      text: Guide
      link: /guide/
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/HERALD

features:
  - title: One handler, declared once
    details: The communicator, the rank, the ranks of the run and of the node, rank-prefixed messages and a fatal path that stops every rank.
  - title: Accounting of time and memory
    details: Named timers reduced over the ranks, and the memory budget of each rank from the node's memory and the job's cgroup limit.
  - title: No dependencies
    details: MPI, the compiler and Linux; without MPI, a single-rank stub with the same interface. Tested with gfortran, nvfortran and ifx.
---
