do step=1, 3
   call mpih%tic(name='solve', sync=.true.)
   call solve                                ! rank 0 takes 20 ms, rank 1 takes 40 ms
   seconds = mpih%toc(name='solve')
enddo
