!< HERALD documentation example, tutorial 5: a handler on a communicator of the program.
!run t05_comm mpirun --oversubscribe -np 4 t05_comm
program t05_comm
use :: mpi
use :: herald
implicit none
type(mpih_object) :: world, half
integer           :: color, comm, ierr

!region world
call world%initialize ! MPI is initialized here: this handler owns it
!endregion world
!region split
color = mod(world%myrank, 2)
call MPI_COMM_SPLIT(world%comm, color, world%myrank, comm, ierr)
call half%initialize(comm=comm)
!endregion split
if (world%is_root()) then
   print '(A,I0)', 'ranks of the run:            ', world%procs_number
   print '(A,I0)', 'ranks of my half:            ', half%procs_number
   print '(A,L1)', 'the half owns MPI:           ', half%owns_mpi
endif
!region timers
call half%tic(name='half work', sync=.true.) ! the barrier and the reductions are those of the half
if (half%toc(name='half work') < 0) call world%error_stop(msg='impossible')
!endregion timers
!region finalize
call half%finalize  ! frees the half's node communicator; MPI lives on
call world%finalize ! finalizes MPI
!endregion finalize
endprogram t05_comm
