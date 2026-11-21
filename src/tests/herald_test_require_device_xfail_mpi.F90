!< HERALD test (expected failure): a required device that is not there stops the run.
program herald_test_require_device_xfail_mpi
!< HERALD test (expected failure): a required device that is not there stops the run.
!<
!< `initialize(do_device_init=.true., require_device=.true.)` on the host must stop every rank, non-zero (the
!< host-fallback policy). On a machine with a device the binding succeeds: the test then stops by itself, to stay an
!< expected failure.
use :: herald
implicit none
type(mpih_object) :: mpih !< The handler.

call mpih%initialize(do_device_init=.true., require_device=.true.)
call mpih%error_stop(msg='herald_test_require_device_xfail_mpi: a device is there (expected failure by hand)')
endprogram herald_test_require_device_xfail_mpi
