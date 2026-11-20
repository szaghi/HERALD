!< HERALD, the kinds of the library.
module herald_kinds
!< HERALD, the kinds of the library.
!<
!< HERALD has no dependencies: its kinds come from `iso_fortran_env`, under the names PENF gives them. They are the
!< library's own: the entry module `herald` does not re-export them (see there).
use, intrinsic :: iso_fortran_env, only : int32, int64, real64
implicit none
private
public :: I4P, I8P, R8P

integer, parameter :: I4P = int32  !< 32-bit integer: ranks, counts, MPI handles and error codes.
integer, parameter :: I8P = int64  !< 64-bit integer: bytes.
integer, parameter :: R8P = real64 !< 64-bit real: seconds (MPI_WTIME's kind is double precision).
endmodule herald_kinds
