write(number, '(I0)') mpih%procs_number
call mpih%print_message('ranks of the run: '//trim(number), root_only=.true.)
write(number, '(I0)') mpih%node_procs_number
call mpih%print_message('ranks on my node: '//trim(number), root_only=.true.)
if (mpih%is_root()) call mpih%warning('warnings go to the standard error')
