!< HERALD, the timers class: named, accumulating wall-clock timers with a report over the ranks.
module herald_timer_object
!< HERALD, the timers class: named, accumulating wall-clock timers with a report over the ranks.
!<
!< A timer is created by the first `start` of its name; each `start`/`stop` pair adds its interval to the timer's
!< total and counts one call. Names are looked up by linear search: meant for tens of regions timed around whole
!< phases, not inside hot loops. `statistics` and `report` reduce the totals over the ranks (minimum, mean, maximum):
!< the ratio maximum/mean of a region is its load imbalance.
!<
!< Two synchronizations, both off unless asked:
!<
!< - **device**: a region that launches asynchronous device work is timed wrongly unless the device queue is drained.
!<   HERALD's timers know no device runtime: the program (or HERALD's device layer) registers a procedure with
!<   `set_device_sync`, called at every `start` and `stop`;
!< - **ranks**: `sync=.true.` adds a barrier on the communicator, for timings that must start together. A barrier in
!<   every timed region distorts what is measured: it is never the default.
use :: herald_kinds,   only : I4P, I8P, R8P
use :: herald_mpi
use :: herald_strings, only : str
implicit none
private
public :: timer_object
public :: device_sync_interface
public :: TIMER_NAME_LEN

integer(I4P), parameter :: TIMER_NAME_LEN=48 !< Maximum length of a timer's name (longer names are cut).

abstract interface
   subroutine device_sync_interface()
   !< Drain the device queue (e.g. `!$acc wait`).
   endsubroutine device_sync_interface
endinterface

type :: timer_object
   !< Timers class.
   integer(I4P)                               :: comm=HERALD_COMM_NULL !< Communicator of the barriers and the reductions.
   integer(I4P)                               :: timers_number=0_I4P   !< Number of timers.
   character(TIMER_NAME_LEN), allocatable     :: name(:)               !< Names.
   integer(I8P),              allocatable     :: calls(:)              !< Completed start/stop pairs.
   real(R8P),                 allocatable     :: total(:)              !< Accumulated seconds.
   real(R8P),                 allocatable     :: last(:)               !< Seconds of the last completed pair.
   real(R8P),                 allocatable     :: t0(:)                 !< Clock at the last start.
   logical,                   allocatable     :: is_running(:)         !< Started and not yet stopped.
   procedure(device_sync_interface), pointer, nopass :: device_sync=>null() !< Device synchronization, if any.
   contains
      procedure, pass(self) :: elapsed         !< Return the accumulated seconds of a timer on this rank.
      procedure, pass(self) :: index_of        !< Return the index of a timer, 0 if there is none of that name.
      procedure, pass(self) :: initialize      !< Set the communicator and remove every timer.
      procedure, pass(self) :: is_consistent   !< Return true if every rank has the same timers (collective).
      procedure, pass(self) :: report          !< Print the report over the ranks, on rank 0 (collective).
      procedure, pass(self) :: report_string   !< Return the report over the ranks (collective).
      procedure, pass(self) :: reset           !< Zero one timer, or all.
      procedure, pass(self) :: set_device_sync !< Register (or remove) the device synchronization procedure.
      procedure, pass(self) :: start           !< Start a timer, creating it at its first start.
      procedure, pass(self) :: statistics      !< Reduce the totals over the ranks (collective).
      procedure, pass(self) :: stop            !< Stop a timer and add the interval to its total.
endtype timer_object

contains
   function elapsed(self, name) result(seconds)
   !< Return the accumulated seconds of a timer on this rank (0 if there is none of that name).
   class(timer_object), intent(in) :: self    !< Timers.
   character(*),        intent(in) :: name    !< Timer name.
   real(R8P)                       :: seconds !< Accumulated seconds.
   integer(I4P)                    :: t       !< Timer index.

   seconds = 0._R8P
   t = self%index_of(name)
   if (t > 0) seconds = self%total(t)
   endfunction elapsed

   pure function index_of(self, name) result(t)
   !< Return the index of a timer, 0 if there is none of that name.
   class(timer_object), intent(in) :: self  !< Timers.
   character(*),        intent(in) :: name  !< Timer name.
   integer(I4P)                    :: t     !< Timer index.
   character(TIMER_NAME_LEN)       :: name_ !< Name, cut to the maximum length.

   name_ = name
   do t=1, self%timers_number
      if (self%name(t) == name_) return
   enddo
   t = 0_I4P
   endfunction index_of

   subroutine initialize(self, comm)
   !< Set the communicator and remove every timer (the device synchronization is kept).
   class(timer_object), intent(inout) :: self !< Timers.
   integer(I4P),        intent(in)    :: comm !< Communicator of the barriers and the reductions.

   self%comm = comm
   self%timers_number = 0_I4P
   if (allocated(self%name)) deallocate(self%name, self%calls, self%total, self%last, self%t0, self%is_running)
   endsubroutine initialize

   function is_consistent(self)
   !< Return true if every rank has the same timers, in the same order (collective).
   !<
   !< The reductions of `statistics` pair the timers by index: they mean something only if the ranks created the same
   !< timers in the same order. The number of timers and a checksum of the names are reduced: equal minimum and
   !< maximum of both on every rank.
   class(timer_object), intent(in) :: self           !< Timers.
   logical                         :: is_consistent  !< Same timers on every rank.
   real(R8P)                       :: mine(2)        !< Number of timers and checksum of the names.
   real(R8P)                       :: lo(2), hi(2), total(2) !< Reductions.
   integer(I4P)                    :: t, c           !< Counters.

   mine = [real(self%timers_number, R8P), 0._R8P]
   do t=1, self%timers_number
      do c=1, len_trim(self%name(t))
         mine(2) = mine(2) + real(t*c*ichar(self%name(t)(c:c)), R8P)
      enddo
   enddo
   lo = mine ; hi = mine
   if (self%comm /= HERALD_COMM_NULL) call hmpi_reduce(comm=self%comm, x=mine, x_min=lo, x_max=hi, x_sum=total)
   is_consistent = all(nint(lo, I8P) == nint(hi, I8P))
   endfunction is_consistent

   subroutine report(self, unit)
   !< Print the report over the ranks, on rank 0 (collective).
   class(timer_object), intent(in)           :: self   !< Timers.
   integer(I4P),        intent(in), optional :: unit   !< Unit (default: stdout).
   character(:), allocatable                 :: text   !< Report.
   logical                                   :: is_root !< This is rank 0, or there is no communicator.

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
   !< Return the report over the ranks, the same string on every rank (collective).
   !<
   !< One line per timer: calls on this rank, minimum, mean and maximum seconds over the ranks, and the imbalance
   !< maximum/mean. If the ranks do not have the same timers the reductions are meaningless: the report says so and
   !< gives this rank's totals.
   class(timer_object), intent(in) :: self             !< Timers.
   character(:), allocatable       :: text             !< Report.
   character(1), parameter         :: NL=new_line('a') !< New line character.
   real(R8P), allocatable          :: t_min(:), t_mean(:), t_max(:) !< Statistics.
   logical                         :: is_consistent    !< Same timers on every rank.
   character(160)                  :: line             !< Line buffer.
   real(R8P)                       :: imbalance        !< Maximum/mean of a timer.
   integer(I4P)                    :: t                !< Counter.

   call self%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, is_consistent=is_consistent)
   write(line, '(A,T50,A12,3A14,A11)') 'timer', 'calls', 'min [s]', 'mean [s]', 'max [s]', 'max/mean'
   text = trim(line)
   if (.not.is_consistent) text = 'timers differ among the ranks: totals of this rank only'//NL//text
   do t=1, self%timers_number
      imbalance = 1._R8P ; if (t_mean(t) > 0._R8P) imbalance = t_max(t)/t_mean(t)
      write(line, '(A,T50,A12,3ES14.6,F11.3)') trim(self%name(t)), str(self%calls(t)), t_min(t), t_mean(t), t_max(t), imbalance
      text = text//NL//trim(line)
   enddo
   endfunction report_string

   subroutine reset(self, name)
   !< Zero one timer (calls, total, last; it stops if running), or all of them.
   class(timer_object), intent(inout)        :: self !< Timers.
   character(*),        intent(in), optional :: name !< Timer name (default: all).
   integer(I4P)                              :: t, t1, t2 !< Timer indexes.

   t1 = 1_I4P ; t2 = self%timers_number
   if (present(name)) then
      t1 = self%index_of(name) ; t2 = t1
      if (t1 == 0) return
   endif
   do t=t1, t2
      self%calls(t) = 0_I8P ; self%total(t) = 0._R8P ; self%last(t) = 0._R8P ; self%is_running(t) = .false.
   enddo
   endsubroutine reset

   subroutine set_device_sync(self, device_sync)
   !< Register the device synchronization procedure called at every `start` and `stop`; none removes it.
   class(timer_object),              intent(inout)        :: self        !< Timers.
   procedure(device_sync_interface),             optional :: device_sync !< Device synchronization procedure.

   self%device_sync => null()
   if (present(device_sync)) self%device_sync => device_sync
   endsubroutine set_device_sync

   subroutine start(self, name, sync)
   !< Start a timer, creating it at its first start. Starting a running timer restarts its interval.
   class(timer_object), intent(inout)        :: self !< Timers.
   character(*),        intent(in)           :: name !< Timer name.
   logical,             intent(in), optional :: sync !< Barrier on the communicator first (default .false.).
   integer(I4P)                              :: t    !< Timer index.

   t = self%index_of(name)
   if (t == 0) then
      call grow(self)
      t = self%timers_number
      self%name(t) = name
   endif
   call synchronize(self=self, sync=sync)
   self%is_running(t) = .true.
   self%t0(t) = hmpi_wtime()
   endsubroutine start

   subroutine statistics(self, t_min, t_mean, t_max, is_consistent)
   !< Reduce the totals over the ranks: minimum, mean and maximum of each timer (collective).
   !<
   !< If the ranks do not have the same timers (`is_consistent` false) the three arrays hold this rank's totals.
   class(timer_object),    intent(in)            :: self          !< Timers.
   real(R8P), allocatable, intent(out)           :: t_min(:)      !< Minimum over the ranks.
   real(R8P), allocatable, intent(out)           :: t_mean(:)     !< Mean over the ranks.
   real(R8P), allocatable, intent(out)           :: t_max(:)      !< Maximum over the ranks.
   logical,                intent(out), optional :: is_consistent !< Same timers on every rank.
   logical                                       :: is_consistent_ !< Same timers on every rank, local variable.
   integer(I4P)                                  :: n             !< Number of timers.

   n = self%timers_number
   allocate(t_min(n), t_mean(n), t_max(n))
   is_consistent_ = self%is_consistent()
   if (present(is_consistent)) is_consistent = is_consistent_
   if (n == 0) return
   t_min = self%total(1:n) ; t_mean = t_min ; t_max = t_min
   if (is_consistent_ .and. self%comm /= HERALD_COMM_NULL) then
      call hmpi_reduce(comm=self%comm, x=self%total(1:n), x_min=t_min, x_max=t_max, x_sum=t_mean)
      t_mean = t_mean/real(hmpi_size(self%comm), R8P)
   endif
   endsubroutine statistics

   function stop(self, name, sync) result(seconds)
   !< Stop a timer and add the interval to its total; return the interval (0 if the timer is not running).
   class(timer_object), intent(inout)        :: self    !< Timers.
   character(*),        intent(in)           :: name    !< Timer name.
   logical,             intent(in), optional :: sync    !< Barrier on the communicator first (default .false.).
   real(R8P)                                 :: seconds !< Seconds from the start.
   integer(I4P)                              :: t       !< Timer index.

   seconds = 0._R8P
   t = self%index_of(name)
   if (t == 0) return
   if (.not.self%is_running(t)) return
   call synchronize(self=self, sync=sync)
   seconds = hmpi_wtime() - self%t0(t)
   self%is_running(t) = .false.
   self%last(t) = seconds
   self%total(t) = self%total(t) + seconds
   self%calls(t) = self%calls(t) + 1_I8P
   endfunction stop

   ! private non TBP
   subroutine grow(self)
   !< Add one timer, zeroed, doubling the capacity when it is full.
   class(timer_object), intent(inout)     :: self       !< Timers.
   character(TIMER_NAME_LEN), allocatable :: name(:)    !< Larger names.
   integer(I8P),              allocatable :: calls(:)   !< Larger calls.
   real(R8P),                 allocatable :: total(:), last(:), t0(:) !< Larger reals.
   logical,                   allocatable :: is_running(:) !< Larger flags.
   integer(I4P)                           :: n, capacity !< Number of timers, new capacity.

   n = self%timers_number
   capacity = 0_I4P ; if (allocated(self%name)) capacity = size(self%name)
   if (n == capacity) then
      capacity = max(16_I4P, 2_I4P*capacity)
      allocate(name(capacity), calls(capacity), total(capacity), last(capacity), t0(capacity), is_running(capacity))
      if (n > 0) then
         name(1:n) = self%name(1:n) ; calls(1:n) = self%calls(1:n) ; total(1:n) = self%total(1:n)
         last(1:n) = self%last(1:n) ; t0(1:n) = self%t0(1:n) ; is_running(1:n) = self%is_running(1:n)
      endif
      call move_alloc(name, self%name) ; call move_alloc(calls, self%calls) ; call move_alloc(total, self%total)
      call move_alloc(last, self%last) ; call move_alloc(t0, self%t0) ; call move_alloc(is_running, self%is_running)
   endif
   n = n + 1_I4P
   self%timers_number = n
   self%name(n) = '' ; self%calls(n) = 0_I8P ; self%total(n) = 0._R8P ; self%last(n) = 0._R8P ; self%t0(n) = 0._R8P
   self%is_running(n) = .false.
   endsubroutine grow

   subroutine synchronize(self, sync)
   !< Drain the device queue if a procedure is registered, then wait for the ranks if asked.
   class(timer_object), intent(in)           :: self !< Timers.
   logical,             intent(in), optional :: sync !< Barrier on the communicator (default .false.).

   if (associated(self%device_sync)) call self%device_sync()
   if (present(sync)) then
      if (sync .and. self%comm /= HERALD_COMM_NULL) call hmpi_barrier(self%comm)
   endif
   endsubroutine synchronize
endmodule herald_timer_object
