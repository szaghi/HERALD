!< HERALD test: the program of the documentation's quick start (docs/guide/quickstart.md), compiled and run.
program herald_test_quickstart_mpi
!< HERALD test: the program of the documentation's quick start (docs/guide/quickstart.md), compiled and run.
use, intrinsic :: iso_fortran_env, only : int64, real64
use            :: herald
implicit none
type(mpih_object)         :: mpih      !< The MPI handler of the program.
real(real64), allocatable :: field(:)  !< Some work to time.
real(real64)              :: seconds   !< Seconds of the last interval.
integer(int64), parameter :: N=2000000 !< Elements of the field.

call mpih%initialize(do_device_init=.true.)                  ! MPI too, if nobody has initialized it
call mpih%check_memory(bytes_needed=8*N, what='the field')   ! stop every rank, with the numbers, if it does not fit
allocate(field(N))
call mpih%tic(name='fill', sync=.true.)                      ! a named timer; sync: every rank starts together
call random_number(field)
seconds = mpih%toc(name='fill')
if (sum(field) < 0._real64 .or. seconds < 0._real64) call mpih%error_stop(msg='impossible') ! stops every rank, status 1
if (mpih%is_root()) print '(A)', mpih%description()         ! ranks, node, memory budget, device
call mpih%timer%report                                       ! min, mean, max over the ranks, printed by rank 0
call mpih%memory%report                                      ! in use, peak and budget over the ranks
call mpih%print_message('done', root_only=.true.)
call mpih%finalize                                           ! MPI too, if the handler initialized it
endprogram herald_test_quickstart_mpi
