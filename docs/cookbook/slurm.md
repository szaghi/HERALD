---
icon: memory
---

# Run under Slurm

A job that asks for part of a node's memory (`--mem`, `--mem-per-cpu`) lives in a memory cgroup with that limit.
`/proc/meminfo` still shows the whole node: a program that sizes itself from it is killed by the out-of-memory
handler. HERALD reads the cgroup limit, the tightest along the cgroup's path to the root (Slurm sets it on the job
and step cgroups, not on the task's), cgroup v1 or v2.

```bash
#!/bin/bash
#SBATCH --nodes=2 --ntasks-per-node=4 --mem=64G
srun --mpi=pmix ./my_program
```

In this job every rank finds `memory%limit_source == 'cgroup'`, `memory%limit` of 64 GB and
`memory%per_rank()` of 16 GB: the limit of its node divided by the four ranks on it.

To see what a run found, on rank 0:

```fortran
if (mpih%is_root()) print '(A)', mpih%description()
```

and, at the end, what it used over the ranks (collective):

```fortran
call mpih%memory%report
```

With no cgroup limit (a workstation, an exclusive node) the limit is the node's memory and the source is `node`.
