!< HERALD documentation example, tutorial 3: named timers and their report over the ranks.
!run t03_timers mpirun --oversubscribe -np 2 t03_timers
program t03_timers
use, intrinsic :: iso_fortran_env, only : int64, real64
use            :: herald
implicit none
type(mpih_object)           :: mpih
real(real64),   allocatable :: t_min(:), t_mean(:), t_max(:), per_call(:), cpu_wall(:)
integer(int64), allocatable :: calls(:)
real(real64)                :: seconds
character(:),   allocatable :: csv
integer                     :: step, unit

call mpih%initialize
!region loop
do step=1, 3
   call mpih%tic(name='solve', sync=.true.)
   call solve                                ! rank 0 takes 20 ms, rank 1 takes 40 ms
   seconds = mpih%toc(name='solve')
enddo
!endregion loop
!region statistics
call mpih%timer%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, calls=calls, per_call=per_call, cpu_wall=cpu_wall)
if (mpih%is_root()) then
   print '(A,I0)',   'calls of all the ranks:        ', calls(1)
   print '(A,L1)',   'fastest rank at least 60 ms:   ', t_min(1) >= 0.06_real64
   print '(A,L1)',   'slowest rank at least 120 ms:  ', t_max(1) >= 0.12_real64
   print '(A,L1)',   'imbalance max/mean above 1.2:  ', t_max(1)/t_mean(1) > 1.2_real64
   print '(A,L1)',   'a call takes 30 ms or more:    ', per_call(1) >= 0.03_real64
   print '(A,L1)',   'CPU/wall below 0.5 (sleeping): ', cpu_wall(1) < 0.5_real64
endif
!endregion statistics
!region report
if (mpih%is_root()) open(newunit=unit, file='timers.txt', action='write', status='replace')
call mpih%timer%report(unit=unit) ! the table, written by rank 0 (collective: every rank calls it)
!endregion report
!region csv
csv = mpih%timer%report_csv_string()
if (mpih%is_root()) print '(A)', csv(1:index(csv, new_line('a'))-1), 'misuses on this rank: '//merge('none', 'some', &
                                 mpih%timer%misuses() == 0)
!endregion csv
call mpih%finalize
contains
   subroutine solve
   !< Stand in for the work: sleep 20 ms on rank 0, 40 ms on rank 1.
   if (mpih%myrank == 0) then
      call execute_command_line('sleep 0.02')
   else
      call execute_command_line('sleep 0.04')
   endif
   endsubroutine solve
endprogram t03_timers
