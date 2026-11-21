!< HERALD, the device layer: the only module that calls a device runtime, or stands in for it.
module herald_device_backend
!< HERALD, the device layer: the only module that calls a device runtime, or stands in for it.
!<
!< The runtime is chosen when HERALD is compiled, and it is the compiler's own (no dependency):
!<
!< - `-DHERALD_OAC`: OpenACC (`openacc` module);
!< - `-DHERALD_OMP`: OpenMP target offloading (`omp_lib` module); OpenMP has no query of the device memory: with
!<   `-DHERALD_HIP` too (AMD/ROCm builds, which link `libamdhip64`) the HIP runtime answers it;
!< - neither: no device runtime, the host only.
!<
!< A host device type (OpenACC `ACC_DEVICE_TYPE=host`, OpenMP with the initial device as default, a machine with no
!< accelerator) counts as no device.
#if defined HERALD_OAC
use            :: openacc
#elif defined HERALD_OMP
use            :: omp_lib
#endif
#if defined HERALD_OMP && defined HERALD_HIP
use, intrinsic :: iso_c_binding, only : C_INT, C_SIZE_T
#endif
use            :: herald_kinds,  only : I4P, I8P
implicit none
private
public :: HERALD_DEVICE_HOST
public :: HERALD_DEVICE_RUNTIME
public :: devb_bind
public :: devb_device_type
public :: devb_devices_number
public :: devb_environment
public :: devb_host_number
public :: devb_memory
public :: devb_start
public :: devb_sync

#if defined HERALD_OAC
character(*), parameter :: HERALD_DEVICE_RUNTIME='openacc'               !< Device runtime of this build.
integer(I4P), parameter :: HERALD_DEVICE_HOST=int(acc_device_host, I4P)  !< Device type of the host.
logical                 :: is_started=.false. !< acc_init already called: some runtimes (libgomp) abort on a second one.
#elif defined HERALD_OMP
character(*), parameter :: HERALD_DEVICE_RUNTIME='openmp'                !< Device runtime of this build.
integer(I4P), parameter :: HERALD_DEVICE_HOST=0_I4P                      !< Device type of the host (1: a device).
#else
character(*), parameter :: HERALD_DEVICE_RUNTIME='none'                  !< Device runtime of this build.
integer(I4P), parameter :: HERALD_DEVICE_HOST=0_I4P                      !< Device type of the host.
#endif

#if defined HERALD_OMP && defined HERALD_HIP
interface
   function hipMemGetInfo(free, total) result(ierr) bind(c, name='hipMemGetInfo')
   !< Query free and total memory of the current HIP device [bytes].
   import :: C_INT, C_SIZE_T
   integer(C_SIZE_T), intent(out) :: free  !< Free device memory [bytes].
   integer(C_SIZE_T), intent(out) :: total !< Total device memory [bytes].
   integer(C_INT)                 :: ierr  !< HIP error code (0 on success).
   endfunction hipMemGetInfo

   function hipSetDevice(device) result(ierr) bind(c, name='hipSetDevice')
   !< Make a device the current HIP device.
   import :: C_INT
   integer(C_INT), value :: device !< Device number.
   integer(C_INT)        :: ierr   !< HIP error code (0 on success).
   endfunction hipSetDevice
endinterface
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

   function devb_device_type() result(device_type)
   !< Return the device type: the OpenACC device type; with OpenMP, which has no such notion, the host's or 1.
   integer(I4P) :: device_type !< Device type, `HERALD_DEVICE_HOST` on the host.

#if defined HERALD_OAC
   device_type = int(acc_get_device_type(), I4P)
#elif defined HERALD_OMP
   device_type = HERALD_DEVICE_HOST
   if (omp_get_num_devices() > 0) then
      if (omp_get_default_device() /= omp_get_initial_device()) device_type = 1_I4P
   endif
#else
   device_type = HERALD_DEVICE_HOST
#endif
   endfunction devb_device_type

   function devb_devices_number() result(devices_number)
   !< Return the number of devices this process can use; 0 on the host.
   integer(I4P) :: devices_number !< Number of devices.

   devices_number = 0_I4P
   if (devb_device_type() == HERALD_DEVICE_HOST) return
#if defined HERALD_OAC
   devices_number = acc_get_num_devices(acc_get_device_type())
#elif defined HERALD_OMP
   devices_number = omp_get_num_devices()
#endif
   endfunction devb_devices_number

   subroutine devb_environment(forced_by, host_requested)
   !< Tell what the environment asks of the runtime: a device at any cost, or the host.
   !<
   !< OpenACC: `ACC_DEVICE_TYPE` naming a device type other than `host` or `multicore` requires a device; those two
   !< request the host. OpenMP: `OMP_TARGET_OFFLOAD=MANDATORY` requires a device, `DISABLED` requests the host. With
   !< no device runtime the host is what the build asked for.
   character(:), allocatable, intent(out) :: forced_by      !< The setting that requires a device, empty if none.
   logical,                   intent(out) :: host_requested !< The host is explicitly requested.
   character(:), allocatable              :: val            !< Value of the variable, upper case.

   forced_by = ''
#if defined HERALD_OAC
   val = env_upper('ACC_DEVICE_TYPE')
   host_requested = (val == 'HOST' .or. val == 'MULTICORE')
   if (len(val) > 0 .and. .not.host_requested) forced_by = 'ACC_DEVICE_TYPE='//val
#elif defined HERALD_OMP
   val = env_upper('OMP_TARGET_OFFLOAD')
   host_requested = (val == 'DISABLED')
   if (val == 'MANDATORY') forced_by = 'OMP_TARGET_OFFLOAD='//val
#else
   val = env_upper('')
   host_requested = .true.
#endif
   endsubroutine devb_environment

   function devb_host_number() result(host_number)
   !< Return the number the runtime gives the host as a device; -1 with no device runtime.
   integer(I4P) :: host_number !< Host device number.

#if defined HERALD_OAC
   host_number = acc_get_device_num(acc_device_host)
#elif defined HERALD_OMP
   host_number = omp_get_initial_device()
#else
   host_number = -1_I4P
#endif
   endfunction devb_host_number

   subroutine devb_memory(device, total, free)
   !< Return the memory of a device, total and free, in bytes; -1 where the runtime does not tell.
   integer(I4P), intent(in)  :: device !< Device number.
   integer(I8P), intent(out) :: total  !< Total memory, bytes.
   integer(I8P), intent(out) :: free   !< Free memory, bytes.
#if defined HERALD_OMP && defined HERALD_HIP
   integer(C_SIZE_T)         :: hip_free, hip_total !< Device memory [bytes].
   integer(C_INT)            :: ierr                !< HIP error code.
#endif

   total = -1_I8P ; free = -1_I8P
#if defined HERALD_OAC
   total = int(acc_get_property(device, acc_get_device_type(), acc_property_memory), I8P)
   free  = int(acc_get_property(device, acc_get_device_type(), acc_property_free_memory), I8P)
#elif defined HERALD_OMP && defined HERALD_HIP
   ierr = hipSetDevice(int(device, C_INT))
   if (ierr == 0) ierr = hipMemGetInfo(hip_free, hip_total)
   if (ierr == 0) then
      total = int(hip_total, I8P) ; free = int(hip_free, I8P)
   endif
#else
   if (device /= device) return ! no query
#endif
   if (total <= 0_I8P) total = -1_I8P
   if (free  <= 0_I8P) free  = -1_I8P
   endsubroutine devb_memory

   subroutine devb_start()
   !< Initialize the device runtime, once per process (OpenACC `acc_init`; nothing to do otherwise).
#if defined HERALD_OAC
   if (is_started) return
   call acc_init(acc_get_device_type())
   is_started = .true.
#endif
   endsubroutine devb_start

   subroutine devb_sync()
   !< Wait for the asynchronous work of the device (OpenACC: every async queue; nothing to wait for otherwise).
#if defined HERALD_OAC
   call acc_wait_all()
#endif
   endsubroutine devb_sync

   ! private non TBP
   function env_upper(name) result(val)
   !< Return the value of an environment variable, upper case and trimmed; empty if unset.
   character(*), intent(in)  :: name   !< Variable name.
   character(:), allocatable :: val    !< Value.
   integer                   :: length !< Length of the value.
   integer                   :: status !< Status.
   integer                   :: c, i   !< Character code, counter.

   val = ''
   if (len(name) == 0) return
   call get_environment_variable(name, length=length, status=status)
   if (status /= 0 .or. length < 1) return
   val = repeat(' ', length)
   call get_environment_variable(name, value=val)
   val = trim(adjustl(val))
   do i=1, len(val)
      c = iachar(val(i:i))
      if (c >= iachar('a') .and. c <= iachar('z')) val(i:i) = achar(c - 32)
   enddo
   endfunction env_upper
endmodule herald_device_backend
