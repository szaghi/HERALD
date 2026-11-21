!< HERALD test (expected failure): asking for more than the rank's memory budget stops the run.
program herald_test_memory_budget_xfail_mpi
!< HERALD test (expected failure): asking for more than the rank's memory budget stops the run.
!<
!< `check_memory` with the budget plus one byte must stop every rank, non-zero. Where the budget is unknown (no /proc)
!< the check passes: the test then stops by itself, to stay an expected failure.
use :: herald
use :: herald_kinds, only : I8P
implicit none
type(mpih_object) :: mpih !< The handler.

call mpih%initialize
if (mpih%memory%per_rank() < 0_I8P) call mpih%error_stop(msg='herald_test_memory_budget_xfail_mpi: unknown budget')
call mpih%check_memory(bytes_needed=mpih%memory%per_rank() + 1_I8P, what='herald_test_memory_budget_xfail_mpi')
call mpih%finalize
endprogram herald_test_memory_budget_xfail_mpi
