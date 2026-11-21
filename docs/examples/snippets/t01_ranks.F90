!< HERALD documentation example, tutorial 1: where the program runs, and who speaks.
program t01_ranks
use :: herald
implicit none
type(mpih_object) :: mpih
character(8)      :: number ! a number as a string

call mpih%initialize(myrankstr_char_length=2)
call mpih%print_message('hello')
write(number, '(I0)') mpih%procs_number
call mpih%print_message('ranks of the run: '//trim(number), root_only=.true.)
write(number, '(I0)') mpih%node_procs_number
call mpih%print_message('ranks on my node: '//trim(number), root_only=.true.)
if (mpih%is_root()) call mpih%warning('warnings go to the standard error')
call mpih%finalize
endprogram t01_ranks
