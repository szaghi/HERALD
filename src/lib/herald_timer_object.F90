!< HERALD, the timers class: named, accumulating wall-clock timers with a report over the ranks.
module herald_timer_object
!< HERALD, the timers class: named, accumulating wall-clock timers with a report over the ranks.
!<
!< A timer is created by the first `start` of its name; each `start`/`stop` pair adds its interval to the timer's
!< total and counts one call. Names are looked up by linear search: meant for tens of regions timed around whole
!< phases, not inside hot loops. `statistics` and `report` reduce the totals over the ranks (minimum, mean, maximum):
!< the ratio maximum/mean of a region is its load imbalance. Each timer also accumulates the CPU time of the process
!< (the ratio CPU/wall tells computing from waiting) and counts its misuses (mismatched `start`/`stop`); the report
!< comes as a table or as CSV.
!<
!< Two synchronizations, both off unless asked:
!<
!< - **device**: a region that launches asynchronous device work is timed wrongly unless the device queue is drained.
!<   HERALD's timers know no device runtime: the program (or HERALD's device layer) registers a procedure with
!<   `set_device_sync`, called at every `start` and `stop`;
!< - **ranks**: `sync=.true.` adds a barrier on the communicator, for timings that must start together. A barrier in
!<   every timed region distorts what is measured: it is never the default.
use, intrinsic :: iso_c_binding, only : C_INT, C_LONG
use :: herald_kinds,   only : I4P, I8P, R8P
use :: herald_mpi
use :: herald_strings, only : str
implicit none
private
public :: timer_object
public :: device_sync_interface
public :: TIMER_NAME_LEN

integer(I4P), parameter :: TIMER_NAME_LEN=48 !< Maximum length of a timer's name (longer names are cut).

type, bind(C) :: c_timespec
   !< POSIX `struct timespec` (Linux: `time_t` and the nanoseconds are both `long`).
   integer(C_LONG) :: tv_sec  !< Seconds.
   integer(C_LONG) :: tv_nsec !< Nanoseconds.
endtype c_timespec

interface
   function c_clock_gettime(clock_id, tp) bind(C, name='clock_gettime') result(ierr)
   !< POSIX clock_gettime.
   import :: C_INT, c_timespec
   integer(C_INT), value :: clock_id !< Clock.
   type(c_timespec)      :: tp       !< Time.
   integer(C_INT)        :: ierr     !< Status.
   endfunction c_clock_gettime
endinterface

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
   integer(I4P),              allocatable     :: clock(:)              !< Clock that answered the last start.
   real(R8P),                 allocatable     :: cpu_total(:)          !< Accumulated CPU seconds of the process.
   real(R8P),                 allocatable     :: cpu0(:)               !< CPU clock at the last start.
   integer(I8P),              allocatable     :: misuse(:)             !< Misuses: see `misuses`.
   integer(I8P)                               :: unknown_stops=0_I8P   !< Stops of a name that was never started.
   procedure(device_sync_interface), pointer, nopass :: device_sync=>null() !< Device synchronization, if any.
   contains
      procedure, pass(self) :: elapsed         !< Return the accumulated seconds of a timer on this rank.
      procedure, pass(self) :: elapsed_cpu     !< Return the accumulated CPU seconds of a timer on this rank.
      procedure, pass(self) :: index_of        !< Return the index of a timer, 0 if there is none of that name.
      procedure, pass(self) :: initialize      !< Set the communicator and remove every timer.
      procedure, pass(self) :: is_consistent   !< Return true if every rank has the same timers (collective).
      procedure, pass(self) :: misuses         !< Return the number of misuses of the timers on this rank.
      procedure, pass(self) :: report          !< Print the report over the ranks, on rank 0 (collective).
      procedure, pass(self) :: report_csv_string !< Return the report over the ranks as CSV (collective).
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

   function elapsed_cpu(self, name) result(seconds)
   !< Return the accumulated CPU seconds of a timer on this rank (0 if there is none of that name).
   class(timer_object), intent(in) :: self    !< Timers.
   character(*),        intent(in) :: name    !< Timer name.
   real(R8P)                       :: seconds !< Accumulated CPU seconds.
   integer(I4P)                    :: t       !< Timer index.

   seconds = 0._R8P
   t = self%index_of(name)
   if (t > 0) seconds = self%cpu_total(t)
   endfunction elapsed_cpu

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
   if (allocated(self%name)) deallocate(self%name, self%calls, self%total, self%last, self%t0, self%is_running, &
                                        self%clock, self%cpu_total, self%cpu0, self%misuse)
   self%unknown_stops = 0_I8P
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

   pure function misuses(self) result(number)
   !< Return the number of misuses of the timers on this rank: a mismatched `start`/`stop` pair is a defect of the
   !< program that the timers would otherwise hide behind a plausible number.
   !<
   !< Counted, per timer: a `stop` of a timer that is not running; a `start` of a running one (its interval restarts);
   !< a `stop` answered by another clock than the `start` (the interval is discarded). And, for all: the stops of a
   !< name that was never started.
   class(timer_object), intent(in) :: self   !< Timers.
   integer(I8P)                    :: number !< Misuses.

   number = self%unknown_stops
   if (self%timers_number > 0) number = number + sum(self%misuse(1:self%timers_number))
   endfunction misuses

   subroutine report(self, unit, csv)
   !< Print the report over the ranks, on rank 0 (collective): the table, or CSV for a program to read.
   class(timer_object), intent(in)           :: self    !< Timers.
   integer(I4P),        intent(in), optional :: unit    !< Unit (default: stdout).
   logical,             intent(in), optional :: csv     !< CSV in place of the table (default .false.).
   character(:), allocatable                 :: text    !< Report.
   logical                                   :: is_root !< This is rank 0, or there is no communicator.
   logical                                   :: csv_    !< CSV, local variable.

   csv_ = .false. ; if (present(csv)) csv_ = csv
   if (csv_) then
      text = self%report_csv_string()
   else
      text = self%report_string()
   endif
   is_root = .true. ; if (self%comm /= HERALD_COMM_NULL) is_root = hmpi_rank(self%comm) == 0_I4P
   if (.not.is_root) return
   if (present(unit)) then
      write(unit, '(A)') text
   else
      print '(A)', text
   endif
   endsubroutine report

   function report_csv_string(self) result(text)
   !< Return the report over the ranks as CSV, the same string on every rank (collective).
   !<
   !< A header and one line per timer: `timer,calls,min_s,mean_s,max_s,max_over_mean,per_call_s,cpu_over_wall,misuses`
   !< (see `statistics`; the name is quoted, a quote in it doubled). A last line `(unknown stops)` holds, under
   !< `misuses`, the stops of names never started. If the ranks do not have the same timers the values are this
   !< rank's (`consistent` in `statistics`): the reader can tell by the first line, `# consistent,true|false`.
   class(timer_object), intent(in) :: self             !< Timers.
   character(:), allocatable       :: text             !< Report.
   character(1), parameter         :: NL=new_line('a') !< New line character.
   real(R8P), allocatable          :: t_min(:), t_mean(:), t_max(:), per_call(:), cpu_wall(:) !< Statistics.
   integer(I8P), allocatable       :: calls(:), misuse(:) !< Statistics.
   integer(I8P)                    :: unknown_stops    !< Stops of names never started.
   logical                         :: is_consistent    !< Same timers on every rank.
   character(200)                  :: line             !< Line buffer.
   character(:), allocatable       :: name             !< Quoted name.
   real(R8P)                       :: imbalance        !< Maximum/mean of a timer.
   integer(I4P)                    :: t, c             !< Counters.

   call self%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, is_consistent=is_consistent, calls=calls, &
                        per_call=per_call, cpu_wall=cpu_wall, misuse=misuse, unknown_stops=unknown_stops)
   text = '# consistent,'//merge('true ', 'false', is_consistent)
   text = trim(text)//NL//'timer,calls,min_s,mean_s,max_s,max_over_mean,per_call_s,cpu_over_wall,misuses'
   do t=1, self%timers_number
      name = ''
      do c=1, len_trim(self%name(t))
         name = name//self%name(t)(c:c)
         if (self%name(t)(c:c) == '"') name = name//'"'
      enddo
      imbalance = 1._R8P ; if (t_mean(t) > 0._R8P) imbalance = t_max(t)/t_mean(t)
      write(line, '(6(A,ES16.9E3))') ',', t_min(t), ',', t_mean(t), ',', t_max(t), ',', imbalance, ',', per_call(t), &
                                     ',', cpu_wall(t)
      text = text//NL//'"'//name//'",'//str(calls(t))//trim(line)//','//str(misuse(t))
   enddo
   text = text//NL//'"(unknown stops)",0,,,,,,,'//str(unknown_stops)
   endfunction report_csv_string

   function report_string(self) result(text)
   !< Return the report over the ranks, the same string on every rank (collective).
   !<
   !< One line per timer (see `statistics`): calls of all the ranks; minimum, mean and maximum seconds over the ranks;
   !< the imbalance maximum/mean; the mean seconds of a call; the ratio CPU/wall. Then the misuses, if any (see
   !< `misuses`). If the ranks do not have the same timers the reductions are meaningless: the report says so and
   !< gives this rank's values.
   class(timer_object), intent(in) :: self             !< Timers.
   character(:), allocatable       :: text             !< Report.
   character(1), parameter         :: NL=new_line('a') !< New line character.
   real(R8P), allocatable          :: t_min(:), t_mean(:), t_max(:), per_call(:), cpu_wall(:) !< Statistics.
   integer(I8P), allocatable       :: calls(:), misuse(:) !< Statistics.
   integer(I8P)                    :: unknown_stops    !< Stops of names never started.
   logical                         :: is_consistent    !< Same timers on every rank.
   character(200)                  :: line             !< Line buffer.
   real(R8P)                       :: imbalance        !< Maximum/mean of a timer.
   integer(I4P)                    :: t                !< Counter.

   call self%statistics(t_min=t_min, t_mean=t_mean, t_max=t_max, is_consistent=is_consistent, calls=calls, &
                        per_call=per_call, cpu_wall=cpu_wall, misuse=misuse, unknown_stops=unknown_stops)
   write(line, '(A,T50,A12,3A14,A10,A14,A10)') 'timer', 'calls', 'min [s]', 'mean [s]', 'max [s]', 'max/mean', &
                                               'per call [s]', 'cpu/wall'
   text = trim(line)
   if (.not.is_consistent) text = 'timers differ among the ranks: values of this rank only'//NL//text
   do t=1, self%timers_number
      imbalance = 1._R8P ; if (t_mean(t) > 0._R8P) imbalance = t_max(t)/t_mean(t)
      write(line, '(A,T50,A12,3ES14.6,F10.3,ES14.6,F10.3)') trim(self%name(t)), str(calls(t)), t_min(t), t_mean(t), &
                                                            t_max(t), imbalance, per_call(t), cpu_wall(t)
      text = text//NL//trim(line)
   enddo
   do t=1, self%timers_number
      if (misuse(t) > 0_I8P) text = text//NL//'misuse: '//str(misuse(t))//' mismatched start/stop of "'// &
                                    trim(self%name(t))//'"'
   enddo
   if (unknown_stops > 0_I8P) text = text//NL//'misuse: '//str(unknown_stops)//' stop(s) of a timer never started'
   endfunction report_string

   subroutine reset(self, name)
   !< Zero one timer (calls, totals, last, misuses; it stops if running), or all of them and the unknown stops.
   class(timer_object), intent(inout)        :: self !< Timers.
   character(*),        intent(in), optional :: name !< Timer name (default: all).
   integer(I4P)                              :: t, t1, t2 !< Timer indexes.

   t1 = 1_I4P ; t2 = self%timers_number
   if (present(name)) then
      t1 = self%index_of(name) ; t2 = t1
      if (t1 == 0) return
   else
      self%unknown_stops = 0_I8P
   endif
   do t=t1, t2
      self%calls(t) = 0_I8P ; self%total(t) = 0._R8P ; self%last(t) = 0._R8P ; self%is_running(t) = .false.
      self%cpu_total(t) = 0._R8P ; self%misuse(t) = 0_I8P
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
   if (self%is_running(t)) self%misuse(t) = self%misuse(t) + 1_I8P ! the interval restarts: its first part is lost
   call synchronize(self=self, sync=sync)
   self%is_running(t) = .true.
   self%cpu0(t) = cpu_seconds()
   self%t0(t) = hmpi_wtime(clock=self%clock(t))
   endsubroutine start

   subroutine statistics(self, t_min, t_mean, t_max, is_consistent, calls, per_call, cpu_wall, misuse, unknown_stops)
   !< Reduce the timers over the ranks (collective).
   !<
   !< - `t_min`, `t_mean`, `t_max`: minimum, mean and maximum over the ranks of each timer's total seconds;
   !< - `calls`: the calls of all the ranks; `per_call`: the seconds of all the ranks divided by them (0 with no call);
   !< - `cpu_wall`: the CPU seconds of all the ranks divided by their wall seconds (0 with no time). The CPU time is
   !<   the process' (POSIX, not the intrinsic `cpu_time`: see `cpu_seconds`): about 1 for a rank that computes; below 1 for one that sleeps or waits for a
   !<   device; above 1 with threads. A rank waiting in MPI may still show about 1: MPI libraries poll;
   !< - `misuse`, `unknown_stops`: the misuses of all the ranks (see `misuses`).
   !<
   !< If the ranks do not have the same timers (`is_consistent` false) everything holds this rank's values.
   class(timer_object),       intent(in)            :: self           !< Timers.
   real(R8P),    allocatable, intent(out)           :: t_min(:)       !< Minimum over the ranks.
   real(R8P),    allocatable, intent(out)           :: t_mean(:)      !< Mean over the ranks.
   real(R8P),    allocatable, intent(out)           :: t_max(:)       !< Maximum over the ranks.
   logical,                   intent(out), optional :: is_consistent  !< Same timers on every rank.
   integer(I8P), allocatable, intent(out), optional :: calls(:)       !< Calls of all the ranks.
   real(R8P),    allocatable, intent(out), optional :: per_call(:)    !< Mean seconds of a call.
   real(R8P),    allocatable, intent(out), optional :: cpu_wall(:)    !< CPU seconds over wall seconds.
   integer(I8P), allocatable, intent(out), optional :: misuse(:)      !< Misuses of all the ranks.
   integer(I8P),              intent(out), optional :: unknown_stops  !< Stops of names never started, all the ranks.
   logical                                          :: is_consistent_ !< Same timers on every rank, local variable.
   real(R8P), allocatable                           :: x(:), lo(:), hi(:), total(:) !< Values and their reductions.
   real(R8P)                                        :: ranks          !< Ranks of the reductions.
   integer(I4P)                                     :: n, t           !< Number of timers, counter.

   n = self%timers_number
   allocate(t_min(n), t_mean(n), t_max(n))
   is_consistent_ = self%is_consistent()
   if (present(is_consistent)) is_consistent = is_consistent_
   ! one reduction of [wall, cpu, calls, misuse](1:n) and the unknown stops
   allocate(x(4*n+1), lo(4*n+1), hi(4*n+1), total(4*n+1))
   if (n > 0) then
      x(1:n) = self%total(1:n) ; x(n+1:2*n) = self%cpu_total(1:n)
      x(2*n+1:3*n) = real(self%calls(1:n), R8P) ; x(3*n+1:4*n) = real(self%misuse(1:n), R8P)
   endif
   x(4*n+1) = real(self%unknown_stops, R8P)
   lo = x ; hi = x ; total = x ; ranks = 1._R8P
   if (is_consistent_ .and. self%comm /= HERALD_COMM_NULL) then
      call hmpi_reduce(comm=self%comm, x=x, x_min=lo, x_max=hi, x_sum=total)
      ranks = real(hmpi_size(self%comm), R8P)
   endif
   t_min = lo(1:n) ; t_max = hi(1:n) ; t_mean = total(1:n)/ranks
   ! allocated here, not by the assignment: nvfortran 26.9 does not size an optional allocatable dummy assigned an
   ! array expression (the calls came back wrong: measured, 2026-11-21)
   if (present(calls)) then
      allocate(calls(n))
      do t=1, n
         calls(t) = nint(total(2*n+t), I8P)
      enddo
   endif
   if (present(misuse)) then
      allocate(misuse(n))
      do t=1, n
         misuse(t) = nint(total(3*n+t), I8P)
      enddo
   endif
   if (present(unknown_stops)) unknown_stops = nint(total(4*n+1), I8P)
   if (present(per_call)) then
      allocate(per_call(n), source=0._R8P)
      do t=1, n
         if (total(2*n+t) > 0._R8P) per_call(t) = total(t)/total(2*n+t)
      enddo
   endif
   if (present(cpu_wall)) then
      allocate(cpu_wall(n), source=0._R8P)
      do t=1, n
         if (total(t) > 0._R8P) cpu_wall(t) = total(n+t)/total(t)
      enddo
   endif
   endsubroutine statistics

   function stop(self, name, sync) result(seconds)
   !< Stop a timer and add the interval to its total; return the interval (0 if the timer is not running).
   !<
   !< An interval started before `MPI_INIT` and stopped after it (or across `MPI_FINALIZE`) is discarded, 0 returned:
   !< its two readings come from different clocks (see `hmpi_wtime`).
   class(timer_object), intent(inout)        :: self    !< Timers.
   character(*),        intent(in)           :: name    !< Timer name.
   logical,             intent(in), optional :: sync    !< Barrier on the communicator first (default .false.).
   real(R8P)                                 :: seconds !< Seconds from the start.
   integer(I4P)                              :: t       !< Timer index.
   real(R8P)                                 :: now     !< Clock at the stop.
   integer(I4P)                              :: clock   !< Clock that answered the stop.
   real(R8P)                                 :: cpu_now !< CPU clock at the stop.

   seconds = 0._R8P
   t = self%index_of(name)
   if (t == 0) then
      self%unknown_stops = self%unknown_stops + 1_I8P
      return
   endif
   if (.not.self%is_running(t)) then
      self%misuse(t) = self%misuse(t) + 1_I8P
      return
   endif
   call synchronize(self=self, sync=sync)
   now = hmpi_wtime(clock=clock)
   self%is_running(t) = .false.
   cpu_now = cpu_seconds()
   if (clock /= self%clock(t)) then ! started on another clock (MPI began or ended since): no interval to measure
      self%misuse(t) = self%misuse(t) + 1_I8P
      return
   endif
   seconds = now - self%t0(t)
   self%last(t) = seconds
   self%total(t) = self%total(t) + seconds
   self%cpu_total(t) = self%cpu_total(t) + max(0._R8P, cpu_now - self%cpu0(t))
   self%calls(t) = self%calls(t) + 1_I8P
   endfunction stop

   ! private non TBP
   function cpu_seconds() result(seconds)
   !< Return the CPU time of the process, all its threads, in seconds (POSIX `CLOCK_PROCESS_CPUTIME_ID`); 0 if the
   !< clock is missing.
   !<
   !< Not the intrinsic `cpu_time`, whose meaning is the compiler's: nvfortran 26.9 returns the wall-clock time (a
   !< 0.3 s sleep gives 0.3 s; gfortran gives 0: measured, 2026-11-21), and the ratio CPU/wall would always be 1.
   real(R8P)                 :: seconds                          !< CPU seconds of the process.
   integer(C_INT), parameter :: CLOCK_PROCESS_CPUTIME_ID=2_C_INT !< Linux value.
   type(c_timespec)          :: tp                               !< Time.

   seconds = 0._R8P
   if (c_clock_gettime(CLOCK_PROCESS_CPUTIME_ID, tp) /= 0_C_INT) return
   seconds = real(tp%tv_sec, R8P) + 1.e-9_R8P*real(tp%tv_nsec, R8P)
   endfunction cpu_seconds

   subroutine grow(self)
   !< Add one timer, zeroed, doubling the capacity when it is full.
   class(timer_object), intent(inout)     :: self       !< Timers.
   character(TIMER_NAME_LEN), allocatable :: name(:)    !< Larger names.
   integer(I8P),              allocatable :: calls(:)   !< Larger calls.
   real(R8P),                 allocatable :: total(:), last(:), t0(:) !< Larger reals.
   logical,                   allocatable :: is_running(:) !< Larger flags.
   integer(I4P),              allocatable :: clock(:)   !< Larger clocks.
   real(R8P),                 allocatable :: cpu_total(:), cpu0(:) !< Larger CPU reals.
   integer(I8P),              allocatable :: misuse(:)  !< Larger misuses.
   integer(I4P)                           :: n, capacity !< Number of timers, new capacity.

   n = self%timers_number
   capacity = 0_I4P ; if (allocated(self%name)) capacity = size(self%name)
   if (n == capacity) then
      capacity = max(16_I4P, 2_I4P*capacity)
      allocate(name(capacity), calls(capacity), total(capacity), last(capacity), t0(capacity), is_running(capacity), &
               clock(capacity), cpu_total(capacity), cpu0(capacity), misuse(capacity))
      if (n > 0) then
         name(1:n) = self%name(1:n) ; calls(1:n) = self%calls(1:n) ; total(1:n) = self%total(1:n)
         last(1:n) = self%last(1:n) ; t0(1:n) = self%t0(1:n) ; is_running(1:n) = self%is_running(1:n)
         clock(1:n) = self%clock(1:n) ; cpu_total(1:n) = self%cpu_total(1:n) ; cpu0(1:n) = self%cpu0(1:n)
         misuse(1:n) = self%misuse(1:n)
      endif
      call move_alloc(name, self%name) ; call move_alloc(calls, self%calls) ; call move_alloc(total, self%total)
      call move_alloc(last, self%last) ; call move_alloc(t0, self%t0) ; call move_alloc(is_running, self%is_running)
      call move_alloc(clock, self%clock) ; call move_alloc(cpu_total, self%cpu_total)
      call move_alloc(cpu0, self%cpu0) ; call move_alloc(misuse, self%misuse)
   endif
   n = n + 1_I4P
   self%timers_number = n
   self%name(n) = '' ; self%calls(n) = 0_I8P ; self%total(n) = 0._R8P ; self%last(n) = 0._R8P ; self%t0(n) = 0._R8P
   self%is_running(n) = .false. ; self%clock(n) = HERALD_CLOCK_SYSTEM
   self%cpu_total(n) = 0._R8P ; self%cpu0(n) = 0._R8P ; self%misuse(n) = 0_I8P
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
