!< HERALD test (expected failure): an error on one rank stops every rank, with a non-zero exit status.
program herald_test_error_stop_xfail_mpi
!< HERALD test (expected failure): an error on one rank stops every rank, with a non-zero exit status.
!<
!< The last rank calls `error_stop`; every other rank waits in a receive that no one will ever match. The run ends
!< (non-zero, as `scripts/run_tests.sh` demands of an `_xfail_` test) only if the fatal path aborts all the ranks: a
!< handler that finalized MPI instead (FUNDAL's did) would leave the launcher waiting for ever. With one rank, or
!< without MPI, the single process stops with exit status 1.
#ifndef HERALD_NO_MPI
use :: mpi
#endif
use :: herald
use :: herald_kinds, only : I4P
implicit none
type(mpih_object) :: mpih !< The handler.
#ifndef HERALD_NO_MPI
integer(I4P)      :: buffer, ierr !< Receive buffer, MPI error status.
#endif

call mpih%initialize
if (mpih%myrank == mpih%procs_number - 1) call mpih%error_stop(msg='herald_test_error_stop_xfail_mpi: expected failure')
#ifndef HERALD_NO_MPI
call MPI_RECV(buffer, 1, MPI_INTEGER, mpih%procs_number - 1, 99, mpih%comm, MPI_STATUS_IGNORE, ierr)
#endif
call mpih%finalize
endprogram herald_test_error_stop_xfail_mpi
