!< HERALD documentation example, tutorial 6: the device of a rank.
!run t06_device mpirun --oversubscribe -np 2 t06_device 2>&1
program t06_device
use :: herald
implicit none
type(mpih_object) :: mpih

!region initialize
call mpih%initialize(do_device_init=.true.)
!endregion initialize
!region query
if (mpih%is_root()) then
   print '(A,A)',  'device runtime of this build: ', HERALD_DEVICE_RUNTIME
   print '(A,L1)', 'running on the host:          ', mpih%device%is_host
   print '(A,I0)', 'devices:                      ', mpih%device%devices_number
   print '(A,I0)', 'my device:                    ', mpih%device%mydev
   print '(A,I0)', 'ranks on my device:           ', mpih%device%sharers
   print '(A,L1)', 'timers wait for the device:   ', associated(mpih%timer%device_sync)
endif
!endregion query
call mpih%finalize
endprogram t06_device
