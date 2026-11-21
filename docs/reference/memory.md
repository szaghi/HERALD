# Memory

Module `herald_memory_object`, type `memory_object`; the handler's is `mpih%memory`. Host memory only: the device's
is in [devices](/reference/device). Linux only: where `/proc` is missing every size is -1 and every check passes.

## Components

| Component | |
|---|---|
| `node_total` | memory of the node, `MemTotal` of `/proc/meminfo` |
| `node_available` | memory available on the node when read (`MemAvailable`, or `MemFree` on old kernels) |
| `cgroup_limit` | memory limit of the process' cgroup, the tightest along its path to the root; -1 if none |
| `limit` | the limit that binds: the smaller of the two |
| `limit_source` | `node`, `cgroup` or `unknown` |
| `node_procs_number` | ranks sharing the node |

All sizes in bytes.

## Methods

| Method | Collective | |
|---|---|---|
| `per_rank()` | no | the budget of this rank: `limit/node_procs_number` |
| `used()` | no | resident memory of the process now (`VmRSS`) |
| `peak()` | no | its highest value (`VmHWM`) |
| `check(bytes_needed, is_ok, msg, what)` | no | `is_ok`: the bytes, plus what is used, fit the budget; `msg`: the numbers in words |
| `update()` | no | read the limits again |
| `description(prefix)` | no | one line per quantity |
| `report(unit)`, `report_string()` | yes | minimum, mean, maximum and sum over the ranks of the use, the peak and the budget, in GB |

On the handler: `check_memory(bytes_needed, what)` stops every rank when `check` fails, and `memory_avail` is the
budget in GB at `initialize`.

## The cgroup limit

The memory controller is found through `/proc/self/cgroup`: a v1 line whose controller list holds `memory` (limit
file `/sys/fs/cgroup/memory<path>/memory.limit_in_bytes`), else the v2 line `0::<path>`
(`/sys/fs/cgroup<path>/memory.max`, which holds `max` when unlimited). Every ancestor is read too.

## The readers

`read_meminfo`, `read_cgroup_limit` and `read_status`, in the module, take their files as optional arguments: the
tests read copies written by the test, since a CI runner cannot reproduce a scheduler's cgroup.
