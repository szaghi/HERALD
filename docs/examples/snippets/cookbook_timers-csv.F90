csv = mpih%timer%report_csv_string()           ! collective: every rank calls it
if (mpih%is_root()) then
   open(newunit=unit, file='timers.csv', action='write', status='replace')
   write(unit, '(A)') csv
   close(unit)
endif
