!< HERALD documentation example, tutorial 4: the memory budget of a rank.
program t04_memory
use, intrinsic :: iso_fortran_env, only : int64, real64
use            :: herald
implicit none
type(mpih_object)         :: mpih
integer(int64)            :: budget, before
real(real64), allocatable :: pool(:)
logical                   :: fits
integer(int64), parameter :: BYTES_PER_CELL=5*8 ! five real64 per cell
integer(int64)            :: cells
character(:), allocatable :: msg

call mpih%initialize
budget = mpih%memory%per_rank() ! bytes; -1 where /proc is missing
if (mpih%is_root()) then
   print '(A,L1)', 'the budget is known:                  ', budget > 0
   print '(A,L1)', 'it is the limit over the node ranks:  ', budget == mpih%memory%limit/mpih%node_procs_number
   print '(A,L1)', 'the limit is the node or the cgroup:  ', mpih%memory%limit_source == 'node' .or. &
                                                             mpih%memory%limit_source == 'cgroup'
endif
call mpih%memory%check(bytes_needed=budget + 1, is_ok=fits, msg=msg, what='a pool too large')
if (mpih%is_root()) print '(A,L1)', 'the budget plus one byte fits:        ', fits
call mpih%check_memory(bytes_needed=64_int64*1024**2, what='the pool') ! would stop every rank, with the numbers
before = mpih%memory%used()
allocate(pool(8*1024**2)) ; pool = 1._real64 ! 64 MB, touched
if (mpih%is_root()) then
   print '(A,L1)', 'the 64 MB of the pool are in use:     ', mpih%memory%used() - before > 48*1024**2
   print '(A,L1)', 'the peak is not below the use:        ', mpih%memory%peak() >= mpih%memory%used()
endif
if (sum(pool) < 1._real64) call mpih%error_stop(msg='impossible')
cells = (8*budget/10)/BYTES_PER_CELL ! 80% of the budget, the rest for everything else
call mpih%check_memory(bytes_needed=cells*BYTES_PER_CELL, what='the cells')
if (mpih%is_root()) print '(A,L1)', 'the cells are sized from the budget:  ', cells > 0
call mpih%finalize
endprogram t04_memory
