!< HERALD, the device class: the device of each rank, the ranks that share it and its memory budget.
module herald_device_object
!< HERALD, the device class: the device of each rank, the ranks that share it and its memory budget.
!<
!< The ranks of a node are bound to its devices round-robin: device `mod(node rank, devices)`. HERALD owns this
!< binding, which the handlers of ADAM and FUNDAL each did on their own, for OpenACC and OpenMP (CUDA Fortran is out of HERALD's scope); the memory
!< management of the device stays with the program (FUNDAL).
!<
!< `sharers` is the number of ranks of the node bound to this rank's device, itself included: the program divides the
!< device's memory by it, so that ranks sharing one device do not each size their pool for the whole of it (ADAM
!< issue #96). A device is identified by the device list the process sees (`CUDA_VISIBLE_DEVICES`,
!< `ROCR_VISIBLE_DEVICES`, `HIP_VISIBLE_DEVICES`) and the number picked in it: ranks launched with the same list share
!< a device when they picked the same number; ranks given different lists (`srun --gpu-bind`) do not. A launcher that
!< shows every rank a distinct device under the same list makes the count err high: a smaller budget, never an
!< oversubscribed device.
use :: herald_device_backend
use :: herald_kinds,   only : I4P, I8P, R8P
use :: herald_mpi
use :: herald_strings, only : str
implicit none
private
public :: device_object

logical :: fallback_warned=.false. !< Host fallback warning already given (once per process).

type :: device_object
   !< Device class.
   integer(I4P) :: devices_number=0_I4P !< Devices this process can use; 0 on the host.
   integer(I4P) :: mydev=-1_I4P         !< Device of this rank, numbered from 0; -1 on the host.
   integer(I4P) :: sharers=1_I4P        !< Ranks of the node bound to this rank's device, itself included.
   integer(I8P) :: memory_total=-1_I8P  !< Memory of the device, bytes; -1 unknown.
   integer(I8P) :: memory_free=-1_I8P   !< Free memory of the device at `initialize`, bytes; -1 unknown.
   logical      :: is_host=.true.       !< No device: the work runs on the host.
   integer(I4P) :: devtype=HERALD_DEVICE_HOST !< Device type of the runtime (`HERALD_DEVICE_HOST` on the host).
   integer(I4P) :: myhos=-1_I4P         !< Number the runtime gives the host as a device; -1 with no runtime.
   contains
      procedure, pass(self) :: description !< Return a pretty-printed description.
      procedure, pass(self) :: initialize  !< Bind this rank to a device and count the ranks that share it (collective).
      procedure, pass(self) :: per_sharer  !< Return this rank's share of the device's memory, bytes.
      procedure, nopass     :: sync        !< Wait for the asynchronous work of the device.
endtype device_object

contains
   function description(self, prefix) result(desc)
   !< Return a pretty-printed description.
   class(device_object), intent(in)           :: self             !< Device.
   character(*),         intent(in), optional :: prefix           !< Prefix of every line.
   character(:), allocatable                  :: desc             !< Description.
   character(1), parameter                    :: NL=new_line('a') !< New line character.
   real(R8P),    parameter                    :: GB=1024._R8P**3  !< Bytes of a gigabyte.
   character(:), allocatable                  :: p                !< Prefix, local variable.

   p = '' ; if (present(prefix)) p = prefix
   desc =       p//'device ('//HERALD_DEVICE_RUNTIME//')'//NL
   desc = desc//p//'  devices_number:        '//str(self%devices_number)//NL
   desc = desc//p//'  mydev:                 '//str(self%mydev)//merge(' (host)', '       ', self%is_host)//NL
   desc = desc//p//'  device type:           '//str(self%devtype)//NL
   desc = desc//p//'  host device number:    '//str(self%myhos)//NL
   desc = desc//p//'  ranks on the device:   '//str(self%sharers)//NL
   desc = desc//p//'  memory total [GB]:     '//str(real(max(self%memory_total, 0_I8P), R8P)/GB, decimals=3_I4P)//NL
   desc = desc//p//'  memory free [GB]:      '//str(real(max(self%memory_free, 0_I8P), R8P)/GB, decimals=3_I4P)//NL
   desc = desc//p//'  budget of a rank [GB]: '//str(real(max(self%per_sharer(), 0_I8P), R8P)/GB, decimals=3_I4P)
   endfunction description

   subroutine initialize(self, node_comm, node_myrank, require_device, error, msg)
   !< Bind this rank to a device and count the ranks that share it (collective on `node_comm`).
   !<
   !< The host fallback has a policy (FUNDAL's): with no device, it is an error (`error` 1, the reason in `msg`) if the
   !< caller requires a device or the environment does (see `devb_environment`); else `msg` carries a warning, once
   !< per process, unless the host was explicitly requested (by the environment, or by a build with no runtime).
   class(device_object), intent(inout) :: self        !< Device.
   integer(I4P),         intent(in)    :: node_comm   !< Node-local communicator.
   integer(I4P),         intent(in)    :: node_myrank !< Rank in the node-local communicator.
   logical,                   intent(in),  optional :: require_device !< Forbid the host fallback (default .false.).
   integer(I4P),              intent(out), optional :: error          !< 1: no device, and one is required; else 0.
   character(:), allocatable, intent(out), optional :: msg            !< The error or the warning; empty if none.
   logical                             :: require_device_ !< Forbid the host fallback, local variable.
   character(:), allocatable           :: forced_by   !< Environment setting that requires a device.
   logical                             :: host_requested !< Host explicitly requested.
   character(:), allocatable           :: msg_        !< Message, local variable.
   integer(I4P)                        :: error_      !< Error, local variable.
   integer(I4P),       parameter       :: KEY_LEN=512 !< Device key length.
   character(20),      parameter       :: VISIBLE(3)=[character(20) :: 'CUDA_VISIBLE_DEVICES', 'ROCR_VISIBLE_DEVICES', &
                                                                       'HIP_VISIBLE_DEVICES'] !< Device-list variables.
   character(KEY_LEN)                  :: key         !< This rank's device key.
   character(KEY_LEN), allocatable     :: keys(:)     !< Device keys of the ranks of the node.
   character(KEY_LEN)                  :: list        !< One device list.
   integer(I4P)                        :: i           !< Counter.

   require_device_ = .false. ; if (present(require_device)) require_device_ = require_device
   call devb_start
   self%devtype = devb_device_type()
   self%myhos = devb_host_number()
   self%devices_number = devb_devices_number()
   self%is_host = self%devices_number < 1_I4P
   error_ = 0_I4P ; msg_ = ''
   if (self%is_host) then
      call devb_environment(forced_by=forced_by, host_requested=host_requested)
      if (require_device_ .or. len(forced_by) > 0) then
         error_ = 1_I4P
         if (require_device_) forced_by = 'require_device=.true.'
         msg_ = 'no device available and host fallback forbidden ('//forced_by//')'
      elseif (.not.(host_requested .or. fallback_warned)) then
         msg_ = 'no device available, running on the host (host fallback); require_device=.true. forbids it'
         fallback_warned = .true.
      endif
   endif
   if (present(error)) error = error_
   if (present(msg)) msg = msg_
   self%mydev = -1_I4P ; self%sharers = 1_I4P ; self%memory_total = -1_I8P ; self%memory_free = -1_I8P
   key = 'host'
   if (.not.self%is_host) then
      self%mydev = mod(node_myrank, self%devices_number)
      call devb_bind(self%mydev)
      call devb_memory(device=self%mydev, total=self%memory_total, free=self%memory_free)
      key = ''
      do i=1, size(VISIBLE)
         call get_environment_variable(trim(VISIBLE(i)), list)
         key = trim(key)//trim(VISIBLE(i))//'='//trim(list)//';'
      enddo
      key = trim(key)//'device='//str(self%mydev)
   endif
   ! the gather is collective: every rank of the node takes part, with or without a device
   allocate(keys(0:hmpi_size(node_comm)-1))
   call hmpi_allgather_characters(comm=node_comm, mine=key, everyone=keys)
   if (.not.self%is_host) self%sharers = count(keys == key)
   endsubroutine initialize

   pure function per_sharer(self) result(bytes)
   !< Return this rank's share of the device's memory: the total divided by the sharers, bytes; -1 unknown.
   class(device_object), intent(in) :: self  !< Device.
   integer(I8P)                     :: bytes !< Share.

   bytes = -1_I8P
   if (self%memory_total > 0_I8P) bytes = self%memory_total/int(max(1_I4P, self%sharers), I8P)
   endfunction per_sharer

   subroutine sync()
   !< Wait for the asynchronous work of the device.
   call devb_sync
   endsubroutine sync
endmodule herald_device_object
