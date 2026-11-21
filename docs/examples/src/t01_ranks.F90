!< HERALD documentation example, tutorial 1: where the program runs, and who speaks.
!run t01_ranks mpirun --oversubscribe -np 3 t01_ranks | sort
program t01_ranks
use :: herald
implicit none
!region declare
type(mpih_object) :: mpih
!endregion declare
character(8)      :: number ! a number as a string

!region initialize
call mpih%initialize(myrankstr_char_length=2)
!endregion initialize
!region everyone
call mpih%print_message('hello')
!endregion everyone
!region root
write(number, '(I0)') mpih%procs_number
call mpih%print_message('ranks of the run: '//trim(number), root_only=.true.)
write(number, '(I0)') mpih%node_procs_number
call mpih%print_message('ranks on my node: '//trim(number), root_only=.true.)
if (mpih%is_root()) call mpih%warning('warnings go to the standard error')
!endregion root
!region finalize
call mpih%finalize
!endregion finalize
endprogram t01_ranks
