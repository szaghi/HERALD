---
icon: memory
---

# Size a pool from the budget

A program that allocates most of its memory once (a block pool, a field for every cell) can size it from what the
rank may use, in place of a number in an input file that is wrong on the next machine.

<<< @/examples/snippets/t04_memory-size.F90{fortran}

- `memory%per_rank()` is the binding limit (the node's memory, or the cgroup's when smaller) divided by the ranks on
  the node, in bytes.
- Leave room for everything else: MPI's own buffers, the I/O library, the stack.
- `check_memory` adds what the process already uses, and stops every rank with the numbers if the sum exceeds the
  budget.

With a device, the same holds for its memory: `device%per_sharer()` is the device's memory divided by the ranks of
the node bound to it.
