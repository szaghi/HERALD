if (mpih%is_root()) then
   print '(A,A)',  'device runtime of this build: ', HERALD_DEVICE_RUNTIME
   print '(A,L1)', 'running on the host:          ', mpih%device%is_host
   print '(A,I0)', 'devices:                      ', mpih%device%devices_number
   print '(A,I0)', 'my device:                    ', mpih%device%mydev
   print '(A,I0)', 'ranks on my device:           ', mpih%device%sharers
   print '(A,L1)', 'timers wait for the device:   ', associated(mpih%timer%device_sync)
endif
