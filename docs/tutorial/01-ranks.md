---
title: 1. Ranks and messages
---

# 1. Ranks and messages

## The handler

<<< @/examples/snippets/t01_ranks-declare.F90{fortran}

<<< @/examples/snippets/t01_ranks-initialize.F90{fortran}

`initialize` initializes MPI (nobody had), reads the rank and the number of ranks, and splits the communicator of
the ranks that share this node's memory. `myrankstr_char_length` is the number of digits of the rank in the message
prefix, 5 by default.

## Everyone speaks, or rank 0 alone

<<< @/examples/snippets/t01_ranks-everyone.F90{fortran}

<<< @/examples/snippets/t01_ranks-root.F90{fortran}

`print_message` writes on the standard output, `warning` on the standard error; both prefix the rank.
`root_only=.true.` keeps the other ranks silent, and `is_root()` is true on rank 0.

## Finalize

<<< @/examples/snippets/t01_ranks-finalize.F90{fortran}

The handler initialized MPI, so it finalizes it.

## Running it

The ranks print in no fixed order: the output is sorted here.

<<< @/examples/output/t01_ranks.txt{text}

::: tip What you learned
One handler, `initialize` and `finalize`, and messages that say who speaks. Reference: [the handler](/reference/handler).
:::
