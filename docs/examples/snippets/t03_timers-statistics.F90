call mpih%timer%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, calls=calls, per_call=per_call, cpu_wall=cpu_wall)
if (mpih%is_root()) then
   print '(A,I0)',   'calls of all the ranks:        ', calls(1)
   print '(A,L1)',   'fastest rank at least 60 ms:   ', t_min(1) >= 0.06_real64
   print '(A,L1)',   'slowest rank at least 120 ms:  ', t_max(1) >= 0.12_real64
   print '(A,L1)',   'imbalance max/mean above 1.2:  ', t_max(1)/t_mean(1) > 1.2_real64
   print '(A,L1)',   'a call takes 30 ms or more:    ', per_call(1) >= 0.03_real64
   print '(A,L1)',   'CPU/wall below 0.5 (sleeping): ', cpu_wall(1) < 0.5_real64
endif
