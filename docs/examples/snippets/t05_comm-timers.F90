call half%tic(name='half work', sync=.true.) ! the barrier and the reductions are those of the half
if (half%toc(name='half work') < 0) call world%error_stop(msg='impossible')
