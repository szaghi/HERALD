!< HERALD test: the named timers, their statistics over the ranks and the timings of the handler.
module herald_test_timers_device
!< A stand-in for a device synchronization, which counts its calls (a module procedure: a procedure pointer to an
!< internal one needs an executable stack).
use :: herald_kinds, only : I4P
implicit none
private
public :: count_device_sync, device_syncs

integer(I4P) :: device_syncs=0_I4P !< Calls of the device synchronization.

contains
   subroutine count_device_sync()
   !< Count the calls.
   device_syncs = device_syncs + 1_I4P
   endsubroutine count_device_sync
endmodule herald_test_timers_device

program herald_test_timers_mpi
!< HERALD test: the named timers, their statistics over the ranks and the timings of the handler.
!<
!< Rank r sleeps (r+1)*0.05 s twice in the timer `sleep`: its total must be within [2, 2+margin] sleeps, with 2 calls,
!< and over the ranks minimum <= mean <= maximum, the minimum being rank 0's and the maximum the last rank's. A timer
!< never started gives 0; a `toc` without `tic` gives 0 and counts nothing; `reset` zeroes. The device synchronization
!< registered is called at every start and stop. A timer created on one rank only makes the timers inconsistent, and
!< the report says so.
use, intrinsic :: iso_c_binding, only : C_INT
use            :: herald
use            :: herald_kinds, only : I4P, I8P, R8P
use            :: herald_test_timers_device, only : count_device_sync, device_syncs
implicit none
interface
   function c_usleep(useconds) bind(C, name='usleep') result(ierr)
   !< POSIX usleep.
   import :: C_INT
   integer(C_INT), value :: useconds !< Microseconds.
   integer(C_INT)        :: ierr     !< Status.
   endfunction c_usleep
endinterface
type(mpih_object)      :: mpih                      !< The handler.
real(R8P), parameter   :: NAP=0.05_R8P              !< Seconds of rank 0's sleep.
real(R8P), parameter   :: MARGIN=0.5_R8P            !< Seconds a total may exceed its sleeps by (a loaded machine).
real(R8P), allocatable :: t_min(:), t_mean(:), t_max(:) !< Statistics.
real(R8P)              :: mine, t, first, last      !< Seconds.
logical                :: is_consistent             !< Same timers on every rank.
character(:), allocatable :: text                   !< Report.
integer(I4P)           :: i, s                      !< Counter, timer index.
integer(C_INT)         :: cerr                      !< usleep status.

call mpih%initialize
mine = real(mpih%myrank + 1, R8P)*NAP
if (mpih%toc(name='never started') > 0._R8P .or. mpih%timer%timers_number /= 0) call fail('toc without tic')
do i=1, 2
   call mpih%tic(name='sleep', sync=.true.)
   cerr = c_usleep(int(mine*1.e6_R8P, C_INT))
   t = mpih%toc(name='sleep')
   if (t < mine .or. t > mine + MARGIN) call fail('interval of sleep out of bounds')
enddo
s = mpih%timer%index_of('sleep')
if (s /= 1 .or. mpih%timer%calls(s) /= 2_I8P) call fail('sleep must be timer 1 with 2 calls')
if (mpih%timer%elapsed('sleep') < 2*mine .or. mpih%timer%elapsed('sleep') > 2*mine + 2*MARGIN) call fail('total of sleep')
if (abs(mpih%timer%last(s) - t) > 0._R8P) call fail('last of sleep is not the last interval')
if (mpih%timer%elapsed('absent') > 0._R8P .or. mpih%timer%index_of('absent') /= 0) call fail('absent timer')
call mpih%timer%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, is_consistent=is_consistent)
if (.not.is_consistent .or. size(t_min) /= 1) call fail('the timers must be consistent, 1 timer')
first = 2*NAP ; last = 2*NAP*mpih%procs_number
if (t_min(1) > t_mean(1) .or. t_mean(1) > t_max(1)) call fail('min <= mean <= max is false')
if (t_min(1) < first .or. t_min(1) > first + 2*MARGIN) call fail('the minimum is not rank 0 total')
if (t_max(1) < last .or. t_max(1) > last + 2*MARGIN) call fail('the maximum is not the last rank total')
text = mpih%timer%report_string()
if (index(text, 'sleep') == 0 .or. index(text, 'differ') /= 0) call fail('report: '//text)
! the anonymous timer, and the timed barriers of ADAM and FUNDAL
call mpih%tic
cerr = c_usleep(int(NAP*1.e6_R8P, C_INT))
t = mpih%toc()
if (t < NAP .or. t > NAP + MARGIN .or. mpih%timer%timers_number /= 2) call fail('anonymous tic toc')
call mpih%barrier(tictoc=.true.)
cerr = c_usleep(int(NAP*1.e6_R8P, C_INT))
call mpih%barrier(tictoc=.true., timing=t)
if (mpih%tictoc_timing() < NAP .or. mpih%tictoc_timing() > mpih%procs_number*NAP + MARGIN) call fail('timed barriers')
if (abs(t - mpih%timing(2)) > 0._R8P .or. mpih%tictoc /= 1) call fail('timing of the second barrier')
! device synchronization: called at each start and stop
call mpih%timer%set_device_sync(device_sync=count_device_sync)
call mpih%tic(name='device') ; t = mpih%toc(name='device')
call mpih%timer%set_device_sync()
call mpih%tic(name='device') ; t = mpih%toc(name='device')
if (device_syncs /= 2) call fail('the device synchronization must be called twice')
! reset
call mpih%timer%reset(name='sleep')
if (mpih%timer%elapsed('sleep') > 0._R8P .or. mpih%timer%calls(s) /= 0_I8P) call fail('reset of sleep')
if (mpih%timer%elapsed('device') <= 0._R8P) call fail('reset of one timer zeroed another')
call mpih%timer%reset
if (mpih%timer%elapsed('device') > 0._R8P .or. mpih%timer%timers_number /= 3) call fail('reset of all')
! a timer of one rank only: inconsistent when there are more ranks
if (mpih%is_root()) call mpih%tic(name='root only')
text = mpih%timer%report_string()
if (mpih%timer%is_consistent() .neqv. (mpih%procs_number == 1)) call fail('consistency with a timer of rank 0 only')
if ((index(text, 'differ') /= 0) .neqv. (mpih%procs_number > 1)) call fail('report of inconsistent timers: '//text)
call mpih%print_message('herald_test_timers_mpi: ok', root_only=.true.)
call mpih%finalize
contains
   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_timers_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_timers_mpi
