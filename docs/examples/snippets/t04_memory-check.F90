call mpih%memory%check(bytes_needed=budget + 1, is_ok=fits, msg=msg, what='a pool too large')
if (mpih%is_root()) print '(A,L1)', 'the budget plus one byte fits:        ', fits
call mpih%check_memory(bytes_needed=64_int64*1024**2, what='the pool') ! would stop every rank, with the numbers
