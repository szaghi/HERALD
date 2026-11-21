!< HERALD documentation example, tutorial 2: an error on one rank stops them all.
program t02_errors
use :: herald
implicit none
type(mpih_object) :: mpih

call mpih%initialize
if (mpih%myrank == 1) call mpih%error_stop(msg='the mesh of this rank is empty')
call mpih%barrier ! rank 0 waits here for rank 1, which will never come
call mpih%print_message('never printed')
call mpih%finalize
endprogram t02_errors
