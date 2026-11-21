---
title: 6. Devices
---

# 6. Devices

## Bind the rank

<<< @/examples/snippets/t06_device-initialize.F90{fortran}

With `do_device_init=.true.` the ranks of a node are bound to its devices in turn: device
`mod(node rank, devices)`. HERALD must be compiled with a device runtime for this: `-DHERALD_OAC` (OpenACC) or
`-DHERALD_OMP` (OpenMP target); see [Installation](/guide/installation).

## Ask

<<< @/examples/snippets/t06_device-query.F90{fortran}

`sharers` is the number of ranks of the node bound to the same device, this one included: a program divides the
device's memory by it (`device%per_sharer()`), so that ranks sharing a device do not each size their pool for the
whole of it.

## Running it

The documentation is built with no device runtime, so the program runs on the host:

<<< @/examples/output/t06_device.txt{text}

The same program with HERALD compiled for OpenACC, three ranks on a node with two GPUs (captured by hand):

<<< @/examples/device/t06_device.txt{text}

Rank 0 and rank 2 share device 0; the timers now wait for the device's asynchronous work before reading the clock.

## No device

With no device the run continues on the host and warns once. To stop instead:
`initialize(do_device_init=.true., require_device=.true.)`, or the environment: `ACC_DEVICE_TYPE` naming a device
type, `OMP_TARGET_OFFLOAD=MANDATORY`.

::: tip What you learned
`do_device_init=.true.`, then `mpih%device`. Reference: [devices](/reference/device). Recipe:
[time a region on a GPU](/cookbook/gpu-timing).
:::
