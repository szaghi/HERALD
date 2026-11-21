!< HERALD, the host memory class: the memory budget of each rank and what the process uses of it.
module herald_memory_object
!< HERALD, the host memory class: the memory budget of each rank and what the process uses of it.
!<
!< The budget of a rank is the memory its node can give, divided by the ranks that share the node:
!<
!< - the node's memory is `MemTotal` of `/proc/meminfo`;
!< - under a batch scheduler (Slurm `--mem`) or in a container the process lives in a memory cgroup, whose limit
!<   `/proc/meminfo` does not show: a pool sized from `MemTotal` is killed by the OOM handler (ADAM on medooza,
!<   2026-10-16: 1 TB nodes, 2 ranks, 425 GB per rank in a 64 GB job). The limit is the tightest along the cgroup's
!<   path to the root (Slurm sets it on the job and step cgroups, the task cgroup being unlimited), v1 or v2;
!< - the divisor is the number of ranks of the node-local communicator, not of the run: the node's memory is shared
!<   only by the ranks resident on it (dividing by the ranks of the run made every added node buy no capacity).
!<
!< What the process uses is read from `/proc/self/status`: `VmRSS` (now) and `VmHWM` (its peak).
!<
!< Linux only: where `/proc` is missing every quantity is -1 (unknown) and `check` always passes. All sizes are bytes.
use :: herald_kinds,   only : I4P, I8P, R8P
use :: herald_mpi
use :: herald_strings, only : str
implicit none
private
public :: memory_object
public :: read_cgroup_limit
public :: read_meminfo
public :: read_status

real(R8P), parameter :: GB=1024._R8P**3 !< Bytes of a gigabyte (GiB).

type :: memory_object
   !< Host memory class.
   integer(I4P)              :: comm=HERALD_COMM_NULL   !< Communicator of the reductions.
   integer(I4P)              :: node_procs_number=1_I4P !< Ranks sharing this node's memory.
   integer(I8P)              :: node_total=-1_I8P       !< Memory of the node (`MemTotal`), bytes; -1 unknown.
   integer(I8P)              :: node_available=-1_I8P   !< Memory available on the node at `update`, bytes; -1 unknown.
   integer(I8P)              :: cgroup_limit=-1_I8P     !< Memory limit of the process' cgroup, bytes; -1 none.
   integer(I8P)              :: limit=-1_I8P            !< The limit that binds: the smaller of the two; -1 unknown.
   character(:), allocatable :: limit_source            !< `node`, `cgroup` or `unknown`.
   contains
      procedure, pass(self) :: check         !< Tell whether a number of bytes fits this rank's budget.
      procedure, pass(self) :: description   !< Return a pretty-printed description.
      procedure, pass(self) :: initialize    !< Set the communicator and the node ranks, and read the limits.
      procedure, nopass     :: peak          !< Return the peak resident memory of the process (`VmHWM`), bytes.
      procedure, pass(self) :: per_rank      !< Return this rank's budget, bytes.
      procedure, pass(self) :: report        !< Print the memory used over the ranks, on rank 0 (collective).
      procedure, pass(self) :: report_string !< Return the memory used over the ranks (collective).
      procedure, pass(self) :: update        !< Read the limits again.
      procedure, nopass     :: used          !< Return the resident memory of the process (`VmRSS`), bytes.
endtype memory_object

contains
   subroutine check(self, bytes_needed, is_ok, msg, what)
   !< Tell whether a number of bytes, on top of what the process uses, fits this rank's budget.
   !<
   !< An unknown budget always fits. `msg` says what was asked, what is used and what the budget is.
   class(memory_object),      intent(in)            :: self         !< Memory.
   integer(I8P),              intent(in)            :: bytes_needed !< Bytes about to be allocated.
   logical,                   intent(out)           :: is_ok        !< They fit.
   character(:), allocatable, intent(out), optional :: msg          !< The numbers, in words.
   character(*),              intent(in),  optional :: what         !< What the bytes are for.
   integer(I8P)                                     :: budget, in_use !< Budget and resident memory, bytes.
   character(:), allocatable                        :: what_        !< What the bytes are for, local variable.

   budget = self%per_rank()
   in_use = max(0_I8P, self%used())
   is_ok = budget < 0_I8P .or. bytes_needed + in_use <= budget
   if (present(msg)) then
      what_ = 'memory' ; if (present(what)) what_ = what
      msg = what_//': '//gb_string(bytes_needed)//' GB needed, '//gb_string(in_use)//' GB in use, budget of the rank '// &
            gb_string(budget)//' GB ('//self%limit_source//' limit '//gb_string(self%limit)//' GB, '//                 &
            str(self%node_procs_number)//' rank(s) on the node)'
   endif
   endsubroutine check

   function description(self, prefix) result(desc)
   !< Return a pretty-printed description.
   class(memory_object), intent(in)           :: self             !< Memory.
   character(*),         intent(in), optional :: prefix           !< Prefix of every line.
   character(:), allocatable                  :: desc             !< Description.
   character(1), parameter                    :: NL=new_line('a') !< New line character.
   character(:), allocatable                  :: p                !< Prefix, local variable.

   p = '' ; if (present(prefix)) p = prefix
   desc =       p//'host memory'//NL
   desc = desc//p//'  node total [GB]:       '//gb_string(self%node_total)//NL
   desc = desc//p//'  node available [GB]:   '//gb_string(self%node_available)//NL
   desc = desc//p//'  cgroup limit [GB]:     '//gb_string(self%cgroup_limit)//NL
   desc = desc//p//'  binding limit:         '//self%limit_source//NL
   desc = desc//p//'  ranks on the node:     '//str(self%node_procs_number)//NL
   desc = desc//p//'  budget of a rank [GB]: '//gb_string(self%per_rank())//NL
   desc = desc//p//'  in use [GB]:           '//gb_string(self%used())//NL
   desc = desc//p//'  peak [GB]:             '//gb_string(self%peak())
   endfunction description

   subroutine initialize(self, comm, node_procs_number)
   !< Set the communicator and the node ranks, and read the limits.
   class(memory_object), intent(inout) :: self              !< Memory.
   integer(I4P),         intent(in)    :: comm              !< Communicator of the reductions.
   integer(I4P),         intent(in)    :: node_procs_number !< Ranks sharing this node's memory.

   self%comm = comm
   self%node_procs_number = max(1_I4P, node_procs_number)
   call self%update
   endsubroutine initialize

   function peak() result(bytes)
   !< Return the peak resident memory of the process (`VmHWM`), bytes; -1 unknown.
   integer(I8P) :: bytes !< Peak resident memory.

   bytes = read_status(key='VmHWM')
   endfunction peak

   pure function per_rank(self) result(bytes)
   !< Return this rank's budget: the binding limit divided by the ranks on the node, bytes; -1 unknown.
   class(memory_object), intent(in) :: self  !< Memory.
   integer(I8P)                     :: bytes !< Budget.

   bytes = -1_I8P
   if (self%limit > 0_I8P) bytes = self%limit/int(self%node_procs_number, I8P)
   endfunction per_rank

   subroutine report(self, unit)
   !< Print the memory used over the ranks, on rank 0 (collective).
   class(memory_object), intent(in)           :: self    !< Memory.
   integer(I4P),         intent(in), optional :: unit    !< Unit (default: stdout).
   character(:), allocatable                  :: text    !< Report.
   logical                                    :: is_root !< This is rank 0, or there is no communicator.

   text = self%report_string()
   is_root = .true. ; if (self%comm /= HERALD_COMM_NULL) is_root = hmpi_rank(self%comm) == 0_I4P
   if (.not.is_root) return
   if (present(unit)) then
      write(unit, '(A)') text
   else
      print '(A)', text
   endif
   endsubroutine report

   function report_string(self) result(text)
   !< Return the memory used over the ranks, the same string on every rank (collective): minimum, mean and maximum
   !< of the resident memory, of its peak and of the budget, and the sum of the peaks.
   class(memory_object), intent(in) :: self             !< Memory.
   character(:), allocatable        :: text             !< Report.
   character(1), parameter          :: NL=new_line('a') !< New line character.
   real(R8P)                        :: mine(3), lo(3), hi(3), total(3) !< In use, peak and budget [GB], and reductions.
   real(R8P)                        :: ranks            !< Ranks of the communicator.
   character(8), parameter          :: label(3)=[character(8) :: 'in use', 'peak', 'budget'] !< Row labels.
   character(120)                   :: line             !< Line buffer.
   integer(I4P)                     :: i                !< Counter.

   mine = [real(self%used(), R8P), real(self%peak(), R8P), real(self%per_rank(), R8P)]/GB
   lo = mine ; hi = mine ; total = mine ; ranks = 1._R8P
   if (self%comm /= HERALD_COMM_NULL) then
      call hmpi_reduce(comm=self%comm, x=mine, x_min=lo, x_max=hi, x_sum=total)
      ranks = real(hmpi_size(self%comm), R8P)
   endif
   write(line, '(A,T20,4A14)') 'host memory [GB]', 'min', 'mean', 'max', 'sum'
   text = trim(line)
   do i=1, 3
      write(line, '(A,T20,4F14.3)') trim(label(i)), lo(i), total(i)/ranks, hi(i), total(i)
      text = text//NL//trim(line)
   enddo
   endfunction report_string

   subroutine update(self)
   !< Read the limits again (the memory available changes; the others only if the process moved cgroup).
   class(memory_object), intent(inout) :: self !< Memory.

   call read_meminfo(total=self%node_total, available=self%node_available)
   self%cgroup_limit = read_cgroup_limit()
   self%limit = self%node_total
   self%limit_source = 'node'
   if (self%cgroup_limit > 0_I8P .and. (self%limit < 0_I8P .or. self%cgroup_limit < self%limit)) then
      self%limit = self%cgroup_limit
      self%limit_source = 'cgroup'
   endif
   if (self%limit < 0_I8P) self%limit_source = 'unknown'
   endsubroutine update

   function used() result(bytes)
   !< Return the resident memory of the process (`VmRSS`), bytes; -1 unknown.
   integer(I8P) :: bytes !< Resident memory.

   bytes = read_status(key='VmRSS')
   endfunction used

   ! public non TBP: the readers, with the files as arguments so that they can be tested on copies
   function read_cgroup_limit(cgroup_file, cgroup_root) result(limit)
   !< Return the memory limit (bytes) of the process' cgroup, the tightest along its path to the root; -1 if none is
   !< set or there is no cgroup memory controller.
   !<
   !< The controller is located through `/proc/self/cgroup`: a v1 line `<id>:<controllers>:<path>` whose controller
   !< list holds `memory` (limit file `<root>/memory<path>/memory.limit_in_bytes`), else the v2 line `0::<path>`
   !< (`<root><path>/memory.max`, which holds `max` when unlimited). The ancestors are read too: Slurm sets the
   !< `--mem` limit on the job and step cgroups while the task cgroup itself is unlimited (measured on medooza, v1).
   character(*), intent(in), optional :: cgroup_file                        !< Default `/proc/self/cgroup`.
   character(*), intent(in), optional :: cgroup_root                        !< Default `/sys/fs/cgroup`.
   integer(I8P)                       :: limit                              !< Memory limit (bytes), -1 if none.
   integer(I8P), parameter            :: UNLIMITED=4611686018427387904_I8P  !< 2**62: v1 gives "no limit" as about 2**63.
   character(999)                     :: line                               !< Line buffer.
   character(:), allocatable          :: file                               !< Cgroup membership file.
   character(:), allocatable          :: path                               !< Cgroup path, walked up to the root.
   character(:), allocatable          :: root                               !< Controller mount point.
   character(:), allocatable          :: leaf                               !< Limit file name.
   integer(I8P)                       :: value                              !< Limit read at one level.
   integer(I4P)                       :: file_unit                          !< File unit.
   integer(I4P)                       :: ios                                !< I/O status.
   integer(I4P)                       :: c1, c2                             !< Positions of the two colons of a line.
   logical                            :: is_v1                              !< A v1 memory controller line was found.

   limit = -1_I8P
   file = '/proc/self/cgroup' ; if (present(cgroup_file)) file = cgroup_file
   root = '/sys/fs/cgroup'    ; if (present(cgroup_root)) root = cgroup_root
   path = ''
   is_v1 = .false.
   open(newunit=file_unit, file=file, status='old', action='read', iostat=ios)
   if (ios /= 0) return
   do
      read(file_unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      c1 = index(line, ':')
      if (c1 == 0) cycle
      c2 = index(line(c1+1:), ':') + c1
      if (c2 == c1) cycle
      if (index(','//line(c1+1:c2-1)//',', ',memory,') > 0) then
         path = trim(line(c2+1:))
         is_v1 = .true.
         exit
      elseif (line(1:c2) == '0::') then
         path = trim(line(c2+1:))
      endif
   enddo
   close(file_unit)
   if (path == '') return
   if (is_v1) then
      root = root//'/memory'
      leaf = '/memory.limit_in_bytes'
   else
      leaf = '/memory.max'
   endif
   do
      if (path == '/') path = '' ! the root level
      open(newunit=file_unit, file=root//path//leaf, status='old', action='read', iostat=ios)
      if (ios == 0) then
         read(file_unit, *, iostat=ios) value ! v2 "max" (no limit) does not read as an integer
         if (ios == 0) then
            if (value > 0_I8P .and. value < UNLIMITED .and. (limit < 0_I8P .or. value < limit)) limit = value
         endif
         close(file_unit)
      endif
      if (path == '') exit
      path = path(1:index(path, '/', back=.true.)-1)
   enddo
   endfunction read_cgroup_limit

   subroutine read_meminfo(total, available, meminfo_file)
   !< Read the memory of the node from `/proc/meminfo`, by key: `MemTotal` and `MemAvailable` (`MemFree` on kernels
   !< older than 3.14, which lack it), in bytes; -1 where the file or the key is missing.
   integer(I8P), intent(out)          :: total        !< `MemTotal`, bytes.
   integer(I8P), intent(out)          :: available    !< `MemAvailable`, bytes.
   character(*), intent(in), optional :: meminfo_file !< Default `/proc/meminfo`.
   character(:), allocatable          :: file         !< File name.
   integer(I8P)                       :: free         !< `MemFree`, bytes.

   file = '/proc/meminfo' ; if (present(meminfo_file)) file = meminfo_file
   total     = read_kb(file=file, key='MemTotal')
   available = read_kb(file=file, key='MemAvailable')
   if (available < 0_I8P) then
      free = read_kb(file=file, key='MemFree')
      available = free
   endif
   endsubroutine read_meminfo

   function read_status(key, status_file) result(bytes)
   !< Return a `kB` entry of `/proc/self/status` (`VmRSS`, `VmHWM`, `VmSize`, ...) in bytes; -1 if missing.
   character(*), intent(in)           :: key         !< Key, without the colon.
   character(*), intent(in), optional :: status_file !< Default `/proc/self/status`.
   integer(I8P)                       :: bytes       !< Value, bytes.

   if (present(status_file)) then
      bytes = read_kb(file=status_file, key=key)
   else
      bytes = read_kb(file='/proc/self/status', key=key)
   endif
   endfunction read_status

   ! private non TBP
   pure function gb_string(bytes) result(s)
   !< Return bytes as gigabytes with 3 decimals, `unknown` if negative.
   integer(I8P), intent(in)  :: bytes !< Bytes.
   character(:), allocatable :: s     !< String.

   if (bytes < 0_I8P) then
      s = 'unknown'
   else
      s = str(real(bytes, R8P)/GB, decimals=3_I4P)
   endif
   endfunction gb_string

   function read_kb(file, key) result(bytes)
   !< Return the value of the line `<key>:   <n> kB` of a /proc file, in bytes; -1 if the file or the key is missing.
   character(*), intent(in) :: file      !< File name.
   character(*), intent(in) :: key       !< Key, without the colon.
   integer(I8P)             :: bytes     !< Value, bytes.
   character(999)           :: line      !< Line buffer.
   integer(I8P)             :: kb        !< Value, kB.
   integer(I4P)             :: file_unit !< File unit.
   integer(I4P)             :: ios       !< I/O status.

   bytes = -1_I8P
   open(newunit=file_unit, file=file, status='old', action='read', iostat=ios)
   if (ios /= 0) return
   do
      read(file_unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      if (index(line, key//':') /= 1) cycle
      read(line(len(key)+2:), *, iostat=ios) kb
      if (ios == 0 .and. kb >= 0_I8P) bytes = kb*1024_I8P
      exit
   enddo
   close(file_unit)
   endfunction read_kb
endmodule herald_memory_object
