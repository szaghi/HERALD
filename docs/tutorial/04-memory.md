---
title: 4. Memory
---

# 4. Memory

## The budget of a rank

<<< @/examples/snippets/t04_memory-budget.F90{fortran}

The budget is the memory the node can give, divided by the ranks that share the node. The node's memory is
`MemTotal`; under a batch scheduler or in a container the process lives in a memory cgroup, whose limit is smaller
and is the one that binds. `limit_source` says which.

## Ask before allocating

<<< @/examples/snippets/t04_memory-check.F90{fortran}

`memory%check` answers with a logical and a message; `check_memory` stops every rank, with the numbers in the
message, if the bytes do not fit on top of what the process already uses. A readable error before the allocation
replaces the kill of the out-of-memory handler after it.

## What the process uses

<<< @/examples/snippets/t04_memory-use.F90{fortran}

`used()` is the resident memory now, `peak()` its highest value so far.

## Running it

<<< @/examples/output/t04_memory.txt{text}

::: tip What you learned
`memory%per_rank()` is what a rank may use; `check_memory` enforces it. Reference: [memory](/reference/memory).
Recipe: [size a pool from the budget](/cookbook/pool).
:::
