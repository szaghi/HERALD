!< HERALD, HPC Environment, Ranks, Accounting, Logging, Devices: the library's entry point.
module herald
!< HERALD, HPC Environment, Ranks, Accounting, Logging, Devices: the library's entry point.
!<
!< A client needs `use herald` only: it gives the MPI handler class `mpih_object` (the program declares its own
!< instance: the library exports no singleton) and the constants of the MPI layer.
!<
!< The kinds of `herald_kinds` are NOT re-exported, on purpose: HERALD has no dependencies and names its kinds as PENF
!< does (`I4P`, `I8P`, `R8P`), so a client that uses both PENF and HERALD would find two entities of one name, an
!< ambiguous reference at the first `integer(I4P)`.
use :: herald_mpi,         only : HERALD_COMM_NULL, HERALD_COMM_WORLD, HERALD_HAS_MPI
use :: herald_mpih_object, only : mpih_object
implicit none
private
public :: HERALD_COMM_NULL
public :: HERALD_COMM_WORLD
public :: HERALD_HAS_MPI
public :: mpih_object
endmodule herald
