!< HERALD, the device layer: the only module that calls a device runtime, or stands in for it.
module herald_device_backend
!< HERALD, the device layer: the only module that calls a device runtime, or stands in for it.
!<
!< The runtime is chosen when HERALD is compiled, and it is the compiler's own (no dependency):
!<
!< - `-DHERALD_OAC`: OpenACC (`openacc` module);
!< - `-DHERALD_OMP`: OpenMP target offloading (`omp_lib` module);
!< - neither: no device runtime, the host only.
!<
!< A host device type (OpenACC `ACC_DEVICE_TYPE=host`, a machine with no accelerator) counts as no device.
#if defined HERALD_OAC
use            :: openacc
#elif defined HERALD_OMP
use            :: omp_lib
#endif
use            :: herald_kinds, only : I4P, I8P
implicit none
private
public :: HERALD_DEVICE_RUNTIME
public :: devb_bind
public :: devb_devices_number
public :: devb_memory
public :: devb_sync

#if defined HERALD_OAC
character(*), parameter :: HERALD_DEVICE_RUNTIME='openacc' !< Device runtime of this build.
#elif defined HERALD_OMP
character(*), parameter :: HERALD_DEVICE_RUNTIME='openmp'  !< Device runtime of this build.
#else
character(*), parameter :: HERALD_DEVICE_RUNTIME='none'    !< Device runtime of this build.
#endif

contains
   subroutine devb_bind(device)
   !< Make `device` (numbered from 0) the device of this process.
   integer(I4P), intent(in) :: device !< Device number.

#if defined HERALD_OAC
   call acc_set_device_num(device, acc_get_device_type())
#elif defined HERALD_OMP
   call omp_set_default_device(device)
#else
   if (device /= device) return ! no device runtime
#endif
   endsubroutine devb_bind

   function devb_devices_number() result(devices_number)
   !< Return the number of devices this process can use; 0 on the host.
   integer(I4P) :: devices_number !< Number of devices.

#if defined HERALD_OAC
   devices_number = 0_I4P
   if (acc_get_device_type() /= acc_device_host) devices_number = acc_get_num_devices(acc_get_device_type())
#elif defined HERALD_OMP
   devices_number = omp_get_num_devices()
#else
   devices_number = 0_I4P
#endif
   endfunction devb_devices_number

   subroutine devb_memory(device, total, free)
   !< Return the memory of a device, total and free, in bytes; -1 where the runtime does not tell (OpenMP has no query).
   integer(I4P), intent(in)  :: device !< Device number.
   integer(I8P), intent(out) :: total  !< Total memory, bytes.
   integer(I8P), intent(out) :: free   !< Free memory, bytes.

   total = -1_I8P ; free = -1_I8P
#if defined HERALD_OAC
   total = int(acc_get_property(device, acc_get_device_type(), acc_property_memory), I8P)
   free  = int(acc_get_property(device, acc_get_device_type(), acc_property_free_memory), I8P)
   if (total <= 0_I8P) total = -1_I8P
   if (free  <= 0_I8P) free  = -1_I8P
#else
   if (device /= device) return ! no query
#endif
   endsubroutine devb_memory

   subroutine devb_sync()
   !< Wait for the asynchronous work of the device (OpenACC: every async queue; nothing to wait for otherwise).
#if defined HERALD_OAC
   call acc_wait_all()
#endif
   endsubroutine devb_sync
endmodule herald_device_backend
