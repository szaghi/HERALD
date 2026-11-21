seconds = mpih%toc(name='kernel')   ! not running: counted
seconds = mpih%toc(name='kernle')   ! a typo, never started: counted
if (mpih%is_root()) print '(A,I0)', 'misuses on this rank:    ', mpih%timer%misuses()
