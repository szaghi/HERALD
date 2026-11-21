!< HERALD test: a handler on a communicator of the caller, in a program that initializes and finalizes MPI itself.
program herald_test_comm_mpi
!< HERALD test: a handler on a communicator of the caller, in a program that initializes and finalizes MPI itself.
!<
!< The ranks are split by parity; each half has its own handler, whose size and rank must be those of the half. The
!< handler did not initialize MPI: its `finalize` must leave MPI alive, and a new `initialize` must work. Built with
!< `-DHERALD_NO_MPI` there is no communicator to split: the program checks the single-rank handler only.
#ifndef HERALD_NO_MPI
use :: mpi
#endif
use :: herald
use :: herald_kinds, only : I4P
use :: herald_mpi,   only : hmpi_is_active, hmpi_start
implicit none
type(mpih_object) :: mpih !< The handler.
#ifndef HERALD_NO_MPI
integer(I4P)      :: world_rank, world_size, half, half_size, half_rank, ierr !< Ranks and sizes, MPI error status.
logical           :: started !< MPI initialized here.

! the program initializes MPI, by HERALD's MPI layer: a bare MPI_INIT dies of SIGFPE in a build with the
! floating-point traps on (see hmpi_start)
call hmpi_start(started=started)
if (.not.started) error stop 'herald_test_comm_mpi: MPI was already initialized'
call MPI_COMM_RANK(MPI_COMM_WORLD, world_rank, ierr)
call MPI_COMM_SIZE(MPI_COMM_WORLD, world_size, ierr)
call MPI_COMM_SPLIT(MPI_COMM_WORLD, mod(world_rank, 2), world_rank, half, ierr)
call MPI_COMM_SIZE(half, half_size, ierr)
call MPI_COMM_RANK(half, half_rank, ierr)
call mpih%initialize(comm=half, do_mpi_init=.false.)
if (mpih%owns_mpi) call fail('the handler owns an MPI it did not initialize')
if (mpih%comm /= half .or. mpih%procs_number /= half_size .or. mpih%myrank /= half_rank) call fail('not the half')
if (half_size /= (world_size + 1 - mod(world_rank, 2))/2) call fail('wrong half size')
if (mpih%node_procs_number > half_size) call fail('node size larger than the half')
call mpih%barrier
call mpih%finalize
if (.not.hmpi_is_active()) call fail('finalize ended an MPI the handler did not initialize')
call mpih%initialize ! again, on all the ranks
if (mpih%procs_number /= world_size .or. mpih%myrank /= world_rank .or. mpih%owns_mpi) call fail('second life is wrong')
call mpih%print_message('herald_test_comm_mpi: ok', root_only=.true.)
call mpih%finalize(do_mpi_finalize=.true.)
if (hmpi_is_active()) call fail('finalize(do_mpi_finalize=.true.) left MPI alive')
#else
call mpih%initialize(do_mpi_init=.false.)
if (mpih%procs_number /= 1 .or. mpih%myrank /= 0 .or. mpih%owns_mpi .or. hmpi_is_active()) call fail('serial handler')
call mpih%finalize
call mpih%print_message('herald_test_comm_mpi: ok (serial build, no MPI)')
#endif
contains
   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_comm_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_comm_mpi
