!< HERALD documentation example, tutorial 2: an error on one rank stops them all.
!run t02_errors mpirun --oversubscribe -np 2 t02_errors 2>&1 | grep 'mpi-'
!run t02_status mpirun --oversubscribe -np 2 t02_errors > /dev/null 2>&1; echo "exit status: $?"
program t02_errors
use :: herald
implicit none
type(mpih_object) :: mpih

call mpih%initialize
!region check
if (mpih%myrank == 1) call mpih%error_stop(msg='the mesh of this rank is empty')
!endregion check
!region wait
call mpih%barrier ! rank 0 waits here for rank 1, which will never come
!endregion wait
call mpih%print_message('never printed')
call mpih%finalize
endprogram t02_errors
