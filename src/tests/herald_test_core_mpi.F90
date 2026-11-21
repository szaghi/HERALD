!< HERALD test: the core of the handler on all the ranks (initialize once, ranks, node ranks, messages, finalize).
program herald_test_core_mpi
!< HERALD test: the core of the handler on all the ranks (initialize once, ranks, node ranks, messages, finalize).
!<
!< The handler initializes MPI and therefore finalizes it. Checked on every rank: the rank is in [0, size-1]; the node
!< rank is in [0, node size-1] and the node size in [1, size]; the prefix has the digits asked for; a second
!< `initialize` (with other arguments) changes nothing; `finalize` ends MPI and the handler can no longer be active.
use :: herald
use :: herald_kinds, only : I4P
use :: herald_mpi,   only : hmpi_is_active, hmpi_reduce
use :: herald_kinds, only : R8P
implicit none
type(mpih_object) :: mpih                 !< The handler.
real(R8P)         :: one(1), s(1), a(1), b(1) !< Reduction buffers: the ranks counted by a sum of ones.
character(:), allocatable :: desc         !< Description.

if (mpih%prefix() /= '') call fail('the prefix is not empty before initialize')
call mpih%initialize(myrankstr_char_length=3_I4P)
if (.not.mpih%is_initialized) call fail('not initialized')
if (HERALD_HAS_MPI .neqv. mpih%owns_mpi) call fail('the handler must own MPI exactly when the library has it')
if (HERALD_HAS_MPI .neqv. hmpi_is_active()) call fail('MPI must be active exactly when the library has it')
if (mpih%myrank < 0 .or. mpih%myrank >= mpih%procs_number) call fail('rank out of [0, size-1]')
if (mpih%node_procs_number < 1 .or. mpih%node_procs_number > mpih%procs_number) call fail('node size out of [1, size]')
if (mpih%node_myrank < 0 .or. mpih%node_myrank >= mpih%node_procs_number) call fail('node rank out of [0, node size-1]')
if (mpih%is_root() .neqv. (mpih%myrank == 0)) call fail('is_root is wrong')
if (len(mpih%myrankstr) /= len('[mpi-000]')) call fail('the prefix has not 3 digits: '//mpih%myrankstr)
if (mpih%prefix() /= mpih%myrankstr) call fail('prefix() is not myrankstr')
one = 1._R8P
call hmpi_reduce(comm=mpih%comm, x=one, x_min=a, x_max=b, x_sum=s)
if (nint(s(1)) /= mpih%procs_number .or. nint(a(1)) /= 1 .or. nint(b(1)) /= 1) call fail('the ranks counted are not size')
! once-only: a second call, with other arguments, changes nothing
call mpih%initialize(myrankstr_char_length=9_I4P, comm=HERALD_COMM_NULL)
if (len(mpih%myrankstr) /= len('[mpi-000]') .or. mpih%comm /= HERALD_COMM_WORLD) call fail('initialize ran twice')
desc = mpih%description()
if (index(desc, 'procs_number') == 0 .or. index(desc, mpih%myrankstr) /= 1) call fail('description: '//desc)
call mpih%barrier
call mpih%print_message('herald_test_core_mpi: ok', root_only=.true.)
call mpih%finalize
if (mpih%is_initialized .or. mpih%owns_mpi .or. hmpi_is_active()) call fail('finalize left the handler or MPI alive')
if (mpih%node_comm /= HERALD_COMM_NULL) call fail('finalize left the node communicator')
contains
   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_core_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_core_mpi
