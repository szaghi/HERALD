# Devices

Module `herald_device_object`, type `device_object`; the handler's is `mpih%device`, filled by
`initialize(do_device_init=.true.)`. HERALD binds ranks to devices and reports on them; allocating and copying
device memory is the program's (or FUNDAL's).

## Components

| Component | |
|---|---|
| `is_host` | no device: the work runs on the host |
| `devices_number` | devices this process can use; 0 on the host |
| `mydev` | device of this rank, numbered from 0; -1 on the host |
| `sharers` | ranks of the node bound to this rank's device, itself included; 1 on the host |
| `memory_total`, `memory_free` | memory of the device, and free at `initialize`, bytes; -1 unknown |
| `devtype` | device type of the runtime; `HERALD_DEVICE_HOST` on the host |
| `myhos` | number the runtime gives the host as a device; -1 with no runtime |

## Methods

| Method | |
|---|---|
| `per_sharer()` | `memory_total/sharers`, bytes; -1 unknown |
| `sync()` | wait for the asynchronous work of the device |
| `description(prefix)` | one line per quantity |

## Binding

Device `mod(node_myrank, devices_number)`: the ranks of a node take its devices in turn.

`sharers` counts the ranks of the node with the same device list (`CUDA_VISIBLE_DEVICES`, `ROCR_VISIBLE_DEVICES`,
`HIP_VISIBLE_DEVICES`) and the same number picked in it. Ranks launched with different lists (`srun --gpu-bind`) do
not share. A launcher that shows every rank a different device under the same list makes the count too high: a
smaller budget, never an oversubscribed device.

## Runtimes

| Compiled with | `HERALD_DEVICE_RUNTIME` | Memory query | Wait |
|---|---|---|---|
| `-DHERALD_OAC` | `openacc` | `acc_get_property` | `acc_wait_all` |
| `-DHERALD_OMP` | `openmp` | none (-1) | nothing to wait for |
| `-DHERALD_OMP -DHERALD_HIP` | `openmp` | AMD's HIP runtime | nothing to wait for |
| neither | `none` | none | nothing |

A host device type counts as no device: OpenACC with `ACC_DEVICE_TYPE=host` or `multicore`, OpenMP whose default
device is the initial one, a machine with no accelerator.

## No device

| | Result |
|---|---|
| `require_device=.true.` | the run stops |
| `ACC_DEVICE_TYPE` names a device type; `OMP_TARGET_OFFLOAD=MANDATORY` | the run stops |
| the host is requested (`ACC_DEVICE_TYPE=host`, `OMP_TARGET_OFFLOAD=DISABLED`, a build with no runtime) | the host, silently |
| otherwise | the host, with one warning per process |
