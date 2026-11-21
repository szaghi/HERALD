!< HERALD documentation example, cookbook: the timers' device synchronization, misuses and CSV.
module cookbook_timers_device
!< A device synchronization of the program (a module procedure: a pointer to an internal one needs an executable stack).
implicit none
integer :: syncs=0 ! calls of the synchronization
contains
   subroutine my_device_sync()
   ! drain the device queue before the clock is read
   !$acc wait
   syncs = syncs + 1
   endsubroutine my_device_sync
endmodule cookbook_timers_device

program cookbook_timers
use, intrinsic :: iso_fortran_env, only : real64
use            :: herald
use            :: cookbook_timers_device
implicit none
type(mpih_object)         :: mpih
real(real64)              :: seconds
character(:), allocatable :: csv
integer                   :: unit

call mpih%initialize
call mpih%timer%set_device_sync(device_sync=my_device_sync)
call mpih%tic(name='kernel')   ! my_device_sync is called here ...
seconds = mpih%toc(name='kernel') ! ... and here
if (mpih%is_root()) print '(A,I0)', 'device synchronizations: ', syncs
seconds = mpih%toc(name='kernel')   ! not running: counted
seconds = mpih%toc(name='kernle')   ! a typo, never started: counted
if (mpih%is_root()) print '(A,I0)', 'misuses on this rank:    ', mpih%timer%misuses()
csv = mpih%timer%report_csv_string()           ! collective: every rank calls it
if (mpih%is_root()) then
   open(newunit=unit, file='timers.csv', action='write', status='replace')
   write(unit, '(A)') csv
   close(unit)
endif
if (mpih%is_root()) call execute_command_line("cut -d, -f1,2,9 timers.csv")
call mpih%finalize
endprogram cookbook_timers
