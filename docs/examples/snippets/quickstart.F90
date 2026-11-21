!< HERALD documentation example: the quick start.
program quickstart
use, intrinsic :: iso_fortran_env, only : int64, real64
use            :: herald
implicit none
type(mpih_object)         :: mpih      ! the MPI handler of the program: declare one, initialize it once
real(real64), allocatable :: field(:)  ! some work to time
real(real64)              :: seconds   ! seconds of the last interval
integer(int64), parameter :: N=2000000 ! elements of the field

call mpih%initialize                                         ! MPI too, if nobody has initialized it
call mpih%check_memory(bytes_needed=8*N, what='the field')   ! stop every rank, with the numbers, if it does not fit
allocate(field(N))
call mpih%tic(name='fill', sync=.true.)                      ! a named timer; sync: every rank starts together
call random_number(field)
seconds = mpih%toc(name='fill')
if (seconds < 0._real64) call mpih%error_stop(msg='impossible') ! stops every rank, exit status 1
call mpih%print_message('ranks: '//merge('two  ', 'other', mpih%procs_number == 2), root_only=.true.)
call mpih%print_message('done', root_only=.true.)
call mpih%finalize                                           ! MPI too, if the handler initialized it
endprogram quickstart
