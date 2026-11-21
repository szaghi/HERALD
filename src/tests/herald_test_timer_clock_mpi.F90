!< HERALD test: a timer never mixes the clock before MPI with the clock of MPI.
program herald_test_timer_clock_mpi
!< HERALD test: a timer never mixes the clock before MPI with the clock of MPI.
!<
!< `hmpi_wtime` reads `system_clock` before `MPI_INIT` and `MPI_WTIME` after it: two origins. A timer started before
!< `MPI_INIT` and stopped after it must discard the interval (0 returned, no call counted), not return the difference
!< of two unrelated readings; started again and stopped, both after `MPI_INIT`, it measures. Built without MPI there
!< is one clock: the first interval is measured too.
use, intrinsic :: iso_c_binding, only : C_INT
use            :: herald
use            :: herald_kinds, only : I4P, I8P, R8P
use            :: herald_mpi,   only : HERALD_CLOCK_MPI, HERALD_CLOCK_SYSTEM, hmpi_wtime
implicit none
interface
   function c_usleep(useconds) bind(C, name='usleep') result(ierr)
   !< POSIX usleep.
   import :: C_INT
   integer(C_INT), value :: useconds !< Microseconds.
   integer(C_INT)        :: ierr     !< Status.
   endfunction c_usleep
endinterface
type(mpih_object)    :: mpih          !< The handler.
type(timer_object)   :: timer         !< A timer of the program, alive before MPI.
real(R8P), parameter :: NAP=0.05_R8P  !< Seconds of a sleep.
real(R8P)            :: t, now        !< Seconds.
integer(I4P)         :: clock         !< Clock that answered.
integer(C_INT)       :: cerr          !< usleep status.

now = hmpi_wtime(clock=clock)
if (clock /= HERALD_CLOCK_SYSTEM .or. now < 0._R8P) call fail('before MPI the clock must be system_clock')
call timer%start(name='across')
cerr = c_usleep(int(NAP*1.e6_R8P, C_INT))
call mpih%initialize
now = hmpi_wtime(clock=clock)
if ((clock == HERALD_CLOCK_MPI) .neqv. HERALD_HAS_MPI) call fail('with MPI active the clock must be MPI_WTIME')
t = timer%stop(name='across')
if (HERALD_HAS_MPI) then
   if (abs(t) > 0._R8P .or. timer%calls(1) /= 0_I8P .or. timer%elapsed('across') > 0._R8P) &
      call fail('an interval across MPI_INIT must be discarded')
else
   if (t < NAP .or. timer%calls(1) /= 1_I8P) call fail('without MPI there is one clock: the interval is measured')
endif
if (timer%is_running(1)) call fail('the timer must be stopped')
if (timer%misuses() /= merge(1_I8P, 0_I8P, HERALD_HAS_MPI)) call fail('a change of clock is a misuse, counted once')
call timer%start(name='across')
cerr = c_usleep(int(NAP*1.e6_R8P, C_INT))
t = timer%stop(name='across')
if (t < NAP .or. t > NAP + 0.5_R8P) call fail('an interval inside MPI must be measured')
call mpih%print_message('herald_test_timer_clock_mpi: ok', root_only=.true.)
call mpih%finalize
contains
   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_timer_clock_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_timer_clock_mpi
