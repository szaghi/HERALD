subroutine my_device_sync()
! drain the device queue before the clock is read
!$acc wait
syncs = syncs + 1
endsubroutine my_device_sync
