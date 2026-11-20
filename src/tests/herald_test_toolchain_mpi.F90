!< HERALD test: the build mode's MPI is wired (compile, link, run on the ranks of scripts/run_tests.sh).
program herald_test_toolchain_mpi
!< HERALD test: the build mode's MPI is wired (compile, link, run on the ranks of scripts/run_tests.sh).
!<
!< A test of the build, not of the library: it holds until the handler has its own tests. Every rank must see the same
!< size and a distinct rank in [0, size-1]; the sum of the ranks, reduced, is size*(size-1)/2. Built with
!< `-DHERALD_NO_MPI` (the serial modes, fpm) there is no MPI: the program only links the library.
#ifndef HERALD_NO_MPI
use :: mpi
use, intrinsic :: ieee_exceptions, only : ieee_get_halting_mode, ieee_set_halting_mode, ieee_usual
#endif
use :: herald
use :: herald_kinds, only : I4P
implicit none
#ifndef HERALD_NO_MPI
integer(I4P) :: myrank, procs_number, ranks_sum, ierr !< Rank, ranks number, sum of the ranks, MPI error status.
logical      :: halting(size(ieee_usual))             !< Halting modes of the program, restored after MPI_INIT.

! MPI_INIT runs with the floating-point traps off: Open MPI 5.0.11's hwloc initialises libxml2, which makes its NaN by
! an invalid operation, and a program built with traps on (gfortran -ffpe-trap=invalid, the debug modes) dies there of
! SIGFPE (measured, 2026-11-20). The handler's initialize will do the same
call ieee_get_halting_mode(ieee_usual, halting)
call ieee_set_halting_mode(ieee_usual, .false.)
call MPI_INIT(ierr)
call ieee_set_halting_mode(ieee_usual, halting)
call MPI_COMM_SIZE(MPI_COMM_WORLD, procs_number, ierr)
call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, ierr)
call MPI_ALLREDUCE(myrank, ranks_sum, 1, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
if (myrank < 0 .or. myrank >= procs_number .or. ranks_sum /= procs_number*(procs_number-1)/2) then
   print '(A,3(1X,I0))', 'herald_test_toolchain_mpi: wrong rank, size, sum of ranks:', myrank, procs_number, ranks_sum
   call MPI_ABORT(MPI_COMM_WORLD, 1_I4P, ierr)
endif
if (myrank == 0) print '(A,I0,A)', 'herald_test_toolchain_mpi: ok (', procs_number, ' ranks)'
call MPI_FINALIZE(ierr)
#else
print '(A)', 'herald_test_toolchain_mpi: ok (serial build, no MPI)'
#endif
endprogram herald_test_toolchain_mpi
