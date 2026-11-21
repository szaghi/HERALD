before = mpih%memory%used()
allocate(pool(8*1024**2)) ; pool = 1._real64 ! 64 MB, touched
if (mpih%is_root()) then
   print '(A,L1)', 'the 64 MB of the pool are in use:     ', mpih%memory%used() - before > 48*1024**2
   print '(A,L1)', 'the peak is not below the use:        ', mpih%memory%peak() >= mpih%memory%used()
endif
