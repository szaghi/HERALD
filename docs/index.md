---
layout: home

hero:
  name: HERALD
  text: HPC Environment, Ranks, Accounting, Logging, Devices
  tagline: The MPI handler of HPC codes, in modern Fortran
  image:
    light: /logo.svg
    dark: /logo-dark.svg
    alt: HERALD, a wild goose carrying a letter across the moon
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
  - icon:
      light: /icons/ranks.svg
      dark: /icons/ranks-dark.svg
      width: 44
      height: 44
    title: One handler, declared once
    details: The communicator, the rank, the ranks of the run and of the node. Initialized once whoever calls it, on any communicator; MPI started on demand and finalized by who started it.
    link: /tutorial/01-ranks
  - icon:
      light: /icons/abort.svg
      dark: /icons/abort-dark.svg
      width: 44
      height: 44
    title: An error stops every rank
    details: A check that one rank alone evaluates ends the whole run, with its message and a non-zero exit status, instead of leaving the others waiting until the time limit.
    link: /tutorial/02-errors
  - icon:
      light: /icons/timers.svg
      dark: /icons/timers-dark.svg
      width: 44
      height: 44
    title: Timers reduced over the ranks
    details: Named, accumulating timers; minimum, mean and maximum over the ranks, load imbalance, seconds per call, CPU over wall time, as a table or as CSV. Mismatched tic/toc are counted.
    link: /tutorial/03-timers
  - icon:
      light: /icons/memory.svg
      dark: /icons/memory-dark.svg
      width: 44
      height: 44
    title: The memory budget of a rank
    details: The node's memory or the cgroup limit of the job, whichever binds, divided by the ranks on the node; the memory in use and its peak; a readable error before an allocation that does not fit.
    link: /tutorial/04-memory
  - icon:
      light: /icons/device.svg
      dark: /icons/device-dark.svg
      width: 44
      height: 44
    title: The device of a rank
    details: Ranks bound to the devices of their node in turn, the ranks sharing each device and its memory share, on OpenACC or OpenMP; the timers wait for the device.
    link: /tutorial/06-device
  - icon:
      light: /icons/serial.svg
      dark: /icons/serial-dark.svg
      width: 44
      height: 44
    title: No dependencies
    details: MPI, the compiler and Linux. Without MPI, a single-rank build with the same interface. Tested with gfortran, nvfortran and ifx; built with FoBiS or fpm.
    link: /guide/installation
---
