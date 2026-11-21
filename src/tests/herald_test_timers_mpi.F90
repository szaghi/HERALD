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
real(R8P), allocatable :: per_call(:), cpu_wall(:)  !< Statistics.
integer(I8P), allocatable :: calls(:), misuse(:)    !< Statistics.
integer(I8P)           :: unknown_stops             !< Stops of names never started, all the ranks.
real(R8P)              :: cpu0, cpu1, x             !< CPU clocks, work.
integer(I4P)           :: b, d, lines               !< Timer indexes, lines of the CSV.

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
call mpih%tic(name='device')
cerr = c_usleep(int(NAP*1.e6_R8P, C_INT)) ! a measurable interval on any clock (the serial one may tick in ms)
t = mpih%toc(name='device')
call mpih%timer%set_device_sync()
call mpih%tic(name='device') ; t = mpih%toc(name='device')
if (device_syncs /= 2) call fail('the device synchronization must be called twice')
! reset
call mpih%timer%reset(name='sleep')
if (mpih%timer%elapsed('sleep') > 0._R8P .or. mpih%timer%calls(s) /= 0_I8P) call fail('reset of sleep')
if (mpih%timer%elapsed('device') <= 0._R8P) call fail('reset of one timer zeroed another')
call mpih%timer%reset
if (mpih%timer%elapsed('device') > 0._R8P .or. mpih%timer%timers_number /= 3) call fail('reset of all')
! CPU time: a rank that computes for about 0.1 s has CPU/wall near 1, one that sleeps has it near 0
if (mpih%timer%misuses() /= 0_I8P) call fail('no misuse is expected after a reset of all')
call mpih%tic(name='busy')
call cpu_time(cpu0) ; cpu1 = cpu0 ; x = 0._R8P ; i = 0
do while (cpu1 - cpu0 < 2*NAP)
   i = i + 1 ; x = x + sin(real(i, R8P))
   if (mod(i, 1000) == 0) call cpu_time(cpu1)
enddo
t = mpih%toc(name='busy')
if (x > real(i, R8P)) call fail('busy work')
call mpih%tic(name='idle')
cerr = c_usleep(int(4*NAP*1.e6_R8P, C_INT))
t = mpih%toc(name='idle')
! the loop above ends on the intrinsic cpu_time, which is the wall clock with nvfortran: a rank descheduled meanwhile
! has used less CPU than that, hence the low bound at a fifth
if (mpih%timer%elapsed_cpu('busy') < 0.4_R8P*NAP .or. &
    mpih%timer%elapsed_cpu('busy') > mpih%timer%elapsed('busy') + NAP) call fail('CPU seconds of busy')
if (mpih%timer%elapsed_cpu('idle') > 2*NAP) call fail('a sleep must use little CPU')
b = mpih%timer%index_of('busy') ; d = mpih%timer%index_of('idle')
call mpih%timer%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, calls=calls, per_call=per_call, cpu_wall=cpu_wall, &
                           misuse=misuse, unknown_stops=unknown_stops)
if (calls(b) /= mpih%procs_number .or. calls(d) /= mpih%procs_number) call fail('calls of all the ranks')
if (abs(per_call(b) - t_mean(b)) > 1.e-9_R8P) call fail('with one call per rank the mean of a call is the mean')
if (cpu_wall(b) < 0.2_R8P .or. cpu_wall(b) > 1.5_R8P) call fail('CPU/wall of busy out of [0.2, 1.5]')
if (cpu_wall(d) > 0.5_R8P .or. cpu_wall(d) >= cpu_wall(b)) call fail('CPU/wall of idle must be small, below busy')
if (any(misuse /= 0_I8P) .or. unknown_stops /= 0_I8P) call fail('no misuse yet')
! misuses: a stop of a stopped timer, a start of a running one, a stop of a name never started
t = mpih%toc(name='busy')
if (t > 0._R8P .or. mpih%timer%misuses() /= 1_I8P) call fail('stop of a stopped timer')
call mpih%tic(name='busy') ; call mpih%tic(name='busy') ; t = mpih%toc(name='busy')
if (mpih%timer%misuses() /= 2_I8P .or. mpih%timer%calls(b) /= 2_I8P) call fail('start of a running timer')
t = mpih%toc(name='nobody') ! its own statement: the operands of an expression are evaluated in any order
if (t > 0._R8P .or. mpih%timer%misuses() /= 3_I8P .or. mpih%timer%unknown_stops /= 1_I8P) &
   call fail('stop of a name never started')
call mpih%timer%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, calls=calls, misuse=misuse, unknown_stops=unknown_stops)
if (misuse(b) /= 2*mpih%procs_number .or. misuse(d) /= 0 .or. unknown_stops /= mpih%procs_number) &
   call fail('misuses of all the ranks')
if (calls(b) /= 2*mpih%procs_number) call fail('calls of busy after the misuses')
text = mpih%timer%report_string()
if (index(text, 'misuse: '//trim(adjustl(int_string(2*mpih%procs_number)))//' mismatched start/stop of "busy"') == 0 .or. &
    index(text, 'never started') == 0 .or. index(text, 'cpu/wall') == 0 .or. index(text, 'per call') == 0) &
   call fail('report with misuses: '//text)
! CSV: the consistency line, the header, one line per timer and the unknown stops
text = mpih%timer%report_csv_string()
lines = 1 ; do i=1, len(text) ; if (text(i:i) == new_line('a')) lines = lines + 1 ; enddo
if (index(text, '# consistent,true') /= 1 .or. lines /= mpih%timer%timers_number + 3) call fail('CSV lines: '//text)
if (index(text, 'timer,calls,min_s,mean_s,max_s,max_over_mean,per_call_s,cpu_over_wall,misuses') == 0) call fail('CSV header')
if (index(text, '"busy",'//trim(adjustl(int_string(2*mpih%procs_number)))//',') == 0) call fail('CSV line of busy: '//text)
if (index(text, '"(unknown stops)",0,,,,,,,'//trim(adjustl(int_string(mpih%procs_number)))) == 0) call fail('CSV unknown')
call mpih%timer%reset
if (mpih%timer%misuses() /= 0_I8P) call fail('reset of all must zero the misuses')
! a timer of one rank only: inconsistent when there are more ranks
if (mpih%is_root()) call mpih%tic(name='root only')
text = mpih%timer%report_string()
if (mpih%timer%is_consistent() .neqv. (mpih%procs_number == 1)) call fail('consistency with a timer of rank 0 only')
if ((index(text, 'differ') /= 0) .neqv. (mpih%procs_number > 1)) call fail('report of inconsistent timers: '//text)
call mpih%print_message('herald_test_timers_mpi: ok', root_only=.true.)
call mpih%finalize
contains
   function int_string(n) result(s)
   !< Integer to string.
   integer(I4P), intent(in) :: n !< Number.
   character(12)            :: s !< String.

   write(s, '(I0)') n
   endfunction int_string

   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_timers_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_timers_mpi
