if (mpih%is_root()) open(newunit=unit, file='timers.txt', action='write', status='replace')
call mpih%timer%report(unit=unit) ! the table, written by rank 0 (collective: every rank calls it)
