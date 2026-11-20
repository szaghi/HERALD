!< HERALD, HPC Environment, Ranks, Accounting, Logging, Devices: the library's entry point.
module herald
!< HERALD, HPC Environment, Ranks, Accounting, Logging, Devices: the library's entry point.
!<
!< Seed of the repository: the module exports nothing yet. The MPI handler (process environment, ranks and node
!< topology, timers and memory budget, rank-prefixed logging and the fatal path, device binding) is added behind this
!< module, so a client needs `use herald` only.
!<
!< The kinds of `herald_kinds` are NOT re-exported, on purpose: HERALD has no dependencies and names its kinds as PENF
!< does (`I4P`, `I8P`, `R8P`), so a client that uses both PENF and HERALD would find two entities of one name, an
!< ambiguous reference at the first `integer(I4P)`.
use herald_kinds
implicit none
private
endmodule herald
