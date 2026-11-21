!< HERALD test: the device of each rank, the ranks that share it and its memory budget.
program herald_test_device_mpi
!< HERALD test: the device of each rank, the ranks that share it and its memory budget.
!<
!< On the host (no device runtime, a host device type, a machine with no accelerator): no device, -1, one sharer, an
!< unknown budget, and no device synchronization in the timers. With devices: the device is `mod(node rank, devices)`,
!< the sharers are in [1, ranks of the node] and sum, over the ranks of a device, to their own number; the budget is
!< the device's memory divided by the sharers; the timers wait for the device.
use :: herald
use :: herald_kinds, only : I8P
implicit none
type(mpih_object) :: mpih !< The handler.

call mpih%initialize(do_device_init=.true.)
associate(device=>mpih%device)
if (device%is_host) then
   if (device%devices_number /= 0 .or. device%mydev /= -1 .or. device%sharers /= 1) call fail('host: no device, 1 sharer')
   if (device%per_sharer() /= -1_I8P) call fail('host: unknown budget')
   if (associated(mpih%timer%device_sync)) call fail('host: the timers must not wait for a device')
else
   if (device%mydev /= mod(mpih%node_myrank, device%devices_number)) call fail('device is not mod(node rank, devices)')
   if (device%sharers < 1 .or. device%sharers > mpih%node_procs_number) call fail('sharers out of [1, node ranks]')
   if (device%memory_total > 0_I8P) then
      if (device%per_sharer() /= device%memory_total/device%sharers) call fail('budget is not total/sharers')
   endif
   if (.not.associated(mpih%timer%device_sync)) call fail('the timers must wait for the device')
   call device%sync
endif
if (index(mpih%description(), 'device ('//HERALD_DEVICE_RUNTIME//')') == 0) call fail('description without the device')
endassociate
call mpih%print_message('herald_test_device_mpi: ok ('//HERALD_DEVICE_RUNTIME//', '// &
                        merge('host  ', 'device', mpih%device%is_host)//')', root_only=.true.)
call mpih%finalize
contains
   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_device_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_device_mpi
