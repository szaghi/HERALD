!< HERALD, the MPI handler class.
module herald_mpih_object
!< HERALD, the MPI handler class.
!<
!< `mpih_object` is the one object an MPI program declares to know where it runs and to speak for its ranks. It keeps
!< the name the handlers of ADAM and FUNDAL had, so a client changes its `use` statement and little else.
!<
!< The library exports the type, not an instance: the program owns its handler.
use, intrinsic :: iso_c_binding,   only : C_INT
use, intrinsic :: iso_fortran_env, only : stderr=>error_unit, stdout=>output_unit
use            :: herald_device_backend, only : devb_sync
use            :: herald_device_object,  only : device_object
use            :: herald_kinds,    only : I4P, I8P, R8P
use            :: herald_memory_object, only : memory_object
use            :: herald_mpi
use            :: herald_strings,  only : str, strz
use            :: herald_timer_object, only : timer_object
implicit none
private
public :: mpih_object

character(*), parameter :: ANONYMOUS_TIMER='tic-toc' !< Name of the timer of `tic` and `toc` without a name.

interface
   function c_usleep(useconds) bind(C, name='usleep') result(ierr)
   !< POSIX usleep: suspend the calling process for `useconds` microseconds.
   import :: C_INT
   integer(C_INT), value :: useconds !< Microseconds.
   integer(C_INT)        :: ierr     !< Status.
   endfunction c_usleep
endinterface

type :: mpih_object
   !< MPI handler class.
   integer(I4P)              :: comm=HERALD_COMM_WORLD     !< Communicator of the handler.
   integer(I4P)              :: node_comm=HERALD_COMM_NULL !< Node-local (shared-memory) communicator, split from `comm`.
   integer(I4P)              :: myrank=0_I4P               !< Rank in `comm`.
   integer(I4P)              :: procs_number=1_I4P         !< Ranks of `comm`.
   integer(I4P)              :: node_myrank=0_I4P          !< Rank in `node_comm`.
   integer(I4P)              :: node_procs_number=1_I4P    !< Ranks of `node_comm`: those sharing this node's memory.
   character(:), allocatable :: myrankstr                  !< Rank prefix of the messages, `[mpi-00000]`.
   integer(I4P)              :: error=0_I4P                !< Error status of the last operation.
   integer(I4P), allocatable :: req_send_recv(:)           !< MPI requests of the program's sends and receives, (0:2*procs_number-1).
   logical                   :: is_initialized=.false.     !< `initialize` ran: later calls return at once.
   logical                   :: owns_mpi=.false.           !< `initialize` initialized MPI: `finalize` finalizes it.
   type(device_object)       :: device                     !< Device of the rank (`initialize(do_device_init=.true.)`).
   type(memory_object)       :: memory                     !< Host memory: the budget of the rank and its use.
   real(R8P)                 :: memory_avail=0._R8P        !< Host memory budget of the rank at `initialize`, GB.
   type(timer_object)        :: timer                      !< Named timers, reduced over the ranks of `comm`.
   real(R8P)                 :: timing(1:2)=0._R8P         !< Clock at the two last timed barriers (`barrier(tictoc=)`).
   integer(I4P)              :: tictoc=1_I4P               !< Slot of `timing` the next timed barrier fills.
   contains
      procedure, pass(self) :: abort         !< Stop every rank with an error code and an optional message.
      procedure, pass(self) :: barrier       !< Block until every rank of `comm` has called it.
      procedure, pass(self) :: check_memory  !< Stop every rank if a number of bytes does not fit the rank's budget.
      procedure, pass(self) :: description   !< Return a pretty-printed description of the handler.
      procedure, pass(self) :: error_stop    !< Stop every rank with an error message, exit status 1.
      procedure, pass(self) :: finalize      !< Free the handler, and finalize MPI if the handler initialized it.
      procedure, pass(self) :: initialize    !< Initialize the handler (once), and MPI if nobody has.
      procedure, pass(self) :: is_root       !< Return true on rank 0 of `comm`.
      procedure, pass(self) :: prefix        !< Return the rank prefix of the messages (empty before `initialize`).
      procedure, pass(self) :: print_message !< Print a message on stdout with the rank prefix.
      procedure, pass(self) :: tic           !< Start a timer (the anonymous one without a name).
      procedure, pass(self) :: tictoc_timing !< Return the seconds between the two last timed barriers.
      procedure, pass(self) :: toc           !< Stop a timer and return the seconds from its `tic`.
      procedure, pass(self) :: warning       !< Print a warning on stderr with the rank prefix.
endtype mpih_object

contains
   subroutine abort(self, error_code, msg)
   !< Stop every rank with an error code and an optional message.
   !<
   !< As `error_stop`, with the code chosen by the caller (default -101, as ADAM's and FUNDAL's handlers); the process'
   !< exit status is 1 in any case, and the launcher reports the code.
   class(mpih_object), intent(inout)        :: self       !< MPI handler.
   integer(I4P),       intent(in), optional :: error_code !< Error code handed to the launcher.
   character(*),       intent(in), optional :: msg        !< Error message.
   integer(I4P)                             :: error_code_ !< Error code, local variable.

   error_code_ = -101_I4P ; if (present(error_code)) error_code_ = error_code
   if (present(msg)) then
      call die(self=self, msg='abort '//msg, error_code=error_code_)
   else
      call die(self=self, msg='abort', error_code=error_code_)
   endif
   endsubroutine abort

   subroutine barrier(self, tictoc, timing, single)
   !< Block until every rank of `comm` has called it (collective); on demand, read the clock after it.
   !<
   !< The timing arguments are those of ADAM's and FUNDAL's handlers: with `tictoc=.true.` the clock after the barrier
   !< fills, in turn, the two slots of `timing(1:2)`, and `tictoc_timing()` returns their difference; `single=.true.`
   !< does not advance to the other slot. New code should use the named timers, `tic(name, sync=.true.)` and `toc`.
   class(mpih_object), intent(inout)         :: self    !< MPI handler.
   logical,            intent(in),  optional :: tictoc  !< Read the clock after the barrier (default .false.).
   real(R8P),          intent(out), optional :: timing  !< The clock read.
   logical,            intent(in),  optional :: single  !< Do not advance to the other slot (default .false.).
   logical                                   :: tictoc_ !< Read the clock, local variable.
   logical                                   :: single_ !< Do not advance, local variable.

   tictoc_ = .false. ; if (present(tictoc)) tictoc_ = tictoc
   single_ = .false. ; if (present(single)) single_ = single
   call hmpi_barrier(self%comm)
   if (present(timing)) timing = 0._R8P
   if (tictoc_) then
      self%timing(self%tictoc) = hmpi_wtime()
      if (present(timing)) timing = self%timing(self%tictoc)
      if (.not.single_) self%tictoc = 3_I4P - self%tictoc
   endif
   endsubroutine barrier

   subroutine check_memory(self, bytes_needed, what)
   !< Stop every rank if a number of bytes, on top of what the process uses, does not fit the rank's memory budget
   !< (see `memory_object%check`): a readable error before the allocation, in place of the OOM handler's kill after.
   class(mpih_object), intent(inout)        :: self         !< MPI handler.
   integer(I8P),       intent(in)           :: bytes_needed !< Bytes about to be allocated.
   character(*),       intent(in), optional :: what         !< What the bytes are for.
   logical                                  :: is_ok        !< They fit.
   character(:), allocatable                :: msg          !< The numbers, in words.

   call self%memory%check(bytes_needed=bytes_needed, is_ok=is_ok, msg=msg, what=what)
   if (.not.is_ok) call self%error_stop(msg='not enough host memory, '//msg)
   endsubroutine check_memory

   function description(self) result(desc)
   !< Return a pretty-printed description of the handler.
   class(mpih_object), intent(in) :: self             !< MPI handler.
   character(:), allocatable      :: desc             !< Description.
   character(1), parameter        :: NL=new_line('a') !< New line character.
   character(:), allocatable      :: p                !< Rank prefix.

   p = self%prefix()
   desc =       p//'MPIH main data'//NL
   desc = desc//p//'  MPI:               '//merge('yes', 'no ', HERALD_HAS_MPI)//NL
   desc = desc//p//'  myrank:            '//str(self%myrank)//NL
   desc = desc//p//'  procs_number:      '//str(self%procs_number)//NL
   desc = desc//p//'  node myrank:       '//str(self%node_myrank)//NL
   desc = desc//p//'  node procs_number: '//str(self%node_procs_number)//NL
   desc = desc//self%memory%description(prefix=p)//NL
   desc = desc//self%device%description(prefix=p)
   endfunction description

   subroutine error_stop(self, msg)
   !< Stop every rank with an error message, exit status 1.
   !<
   !< The error may be rank-local (a check only some ranks evaluate): `MPI_ABORT` on `MPI_COMM_WORLD` terminates all
   !< the ranks. `MPI_FINALIZE` would block the failing rank until the others finalize, while they block forever in
   !< their next collective (ADAM issue #43). The message is flushed first and the rank sleeps 0.5 s before the abort,
   !< so that the launcher forwards it (Open MPI kills the ranks at once, and output not yet forwarded is lost:
   !< measured in ADAM). Without MPI (serial build, not yet initialized, already finalized) the process stops alone.
   !< The exit status is 1: a plain `stop` would make a failed run look successful (ADAM issue #25).
   class(mpih_object), intent(inout)        :: self !< MPI handler.
   character(*),       intent(in), optional :: msg  !< Error message.

   if (present(msg)) then
      call die(self=self, msg='error stop '//msg, error_code=1_I4P)
   else
      call die(self=self, msg='error stop', error_code=1_I4P)
   endif
   endsubroutine error_stop

   subroutine finalize(self, do_mpi_finalize)
   !< Free the handler, and finalize MPI if the handler initialized it.
   !<
   !< Who initializes MPI finalizes it: a program that called `MPI_INIT` itself calls `MPI_FINALIZE` itself, or asks
   !< for it here with `do_mpi_finalize=.true.`. The handler can be initialized again afterwards (while MPI lives).
   class(mpih_object), intent(inout)        :: self             !< MPI handler.
   logical,            intent(in), optional :: do_mpi_finalize  !< Finalize MPI (default: if `initialize` initialized it).
   logical                                  :: do_mpi_finalize_ !< Finalize MPI, local variable.

   do_mpi_finalize_ = self%owns_mpi ; if (present(do_mpi_finalize)) do_mpi_finalize_ = do_mpi_finalize
   call hmpi_free(self%node_comm)
   if (allocated(self%req_send_recv)) deallocate(self%req_send_recv)
   if (do_mpi_finalize_) call hmpi_stop
   self%is_initialized = .false.
   self%owns_mpi = .false.
   endsubroutine finalize

   subroutine initialize(self, comm, do_mpi_init, do_device_init, myrankstr_char_length, verbose, require_device)
   !< Initialize the handler (once), and MPI if nobody has.
   !<
   !< Once-only: a later call returns at once, so that every layer of a program (application, library, test driver) can
   !< call it without repeating the work or leaking a communicator (ADAM issue #80). MPI is initialized on demand, with
   !< the floating-point traps off (see `hmpi_start`); `do_mpi_init=.false.` states that the caller has done it, and
   !< the run stops if it has not.
   !<
   !< `do_device_init=.true.` binds the rank to a device (see `device_object`) and makes the timers wait for the
   !< device's asynchronous work; with no device the run continues on the host with a warning, or stops if a device is
   !< required, by `require_device=.true.` or by the environment (FUNDAL's host-fallback policy).
   class(mpih_object), intent(inout)        :: self                   !< MPI handler.
   integer(I4P),       intent(in), optional :: comm                   !< Communicator (default: all the ranks).
   logical,            intent(in), optional :: do_mpi_init            !< Initialize MPI if nobody has (default .true.).
   logical,            intent(in), optional :: do_device_init         !< Bind the rank to a device (default .false.).
   integer(I4P),       intent(in), optional :: myrankstr_char_length  !< Digits of the rank in the prefix (default 5).
   logical,            intent(in), optional :: verbose                !< Print the description (default .false.).
   logical,            intent(in), optional :: require_device         !< Stop if there is no device (default .false.).
   logical                                  :: do_mpi_init_           !< Initialize MPI, local variable.
   integer(I4P)                             :: myrankstr_char_length_ !< Digits of the rank, local variable.
   logical                                  :: verbose_               !< Print the description, local variable.
   integer(I4P)                             :: device_error           !< Error of the device binding.
   character(:), allocatable                :: device_msg             !< Error or warning of the device binding.

   if (self%is_initialized) return
   do_mpi_init_ = .true. ; if (present(do_mpi_init)) do_mpi_init_ = do_mpi_init
   myrankstr_char_length_ = 5_I4P ; if (present(myrankstr_char_length)) myrankstr_char_length_ = myrankstr_char_length
   verbose_ = .false. ; if (present(verbose)) verbose_ = verbose

   if (do_mpi_init_) then
      call hmpi_start(started=self%owns_mpi)
   elseif (HERALD_HAS_MPI .and. .not.hmpi_is_active()) then
      call self%error_stop(msg='mpih_object%initialize: do_mpi_init=.false., but MPI is not initialized')
   endif
   self%comm = HERALD_COMM_WORLD ; if (present(comm)) self%comm = comm
   self%myrank = hmpi_rank(self%comm)
   self%procs_number = hmpi_size(self%comm)
   self%myrankstr = '[mpi-'//strz(self%myrank, myrankstr_char_length_)//']'
   ! the ranks that share this node's memory: what a node resource (RAM, devices) is divided by
   call hmpi_split_node(comm=self%comm, node_comm=self%node_comm)
   self%node_myrank = hmpi_rank(self%node_comm)
   self%node_procs_number = max(1_I4P, hmpi_size(self%node_comm))
   if (allocated(self%req_send_recv)) deallocate(self%req_send_recv)
   allocate(self%req_send_recv(0:2*self%procs_number-1), source=0_I4P)
   call self%timer%initialize(comm=self%comm)
   call self%memory%initialize(comm=self%comm, node_procs_number=self%node_procs_number)
   self%memory_avail = real(self%memory%per_rank(), R8P)/1024._R8P**3
   if (present(do_device_init)) then
      if (do_device_init) then
         call self%device%initialize(node_comm=self%node_comm, node_myrank=self%node_myrank, &
                                     require_device=require_device, error=device_error, msg=device_msg)
         if (device_error /= 0_I4P) call self%error_stop(msg='mpih_object%initialize: '//device_msg)
         if (len(device_msg) > 0) call self%warning(msg=device_msg)
         if (.not.self%device%is_host) call self%timer%set_device_sync(device_sync=devb_sync)
      endif
   endif
   self%is_initialized = .true.
   if (verbose_) print '(A)', self%description()
   endsubroutine initialize

   pure function is_root(self)
   !< Return true on rank 0 of `comm`.
   class(mpih_object), intent(in) :: self    !< MPI handler.
   logical                        :: is_root !< This is rank 0.

   is_root = self%myrank == 0_I4P
   endfunction is_root

   pure function prefix(self)
   !< Return the rank prefix of the messages (empty before `initialize`).
   class(mpih_object), intent(in) :: self   !< MPI handler.
   character(:), allocatable      :: prefix !< Rank prefix.

   if (allocated(self%myrankstr)) then
      prefix = self%myrankstr
   else
      prefix = ''
   endif
   endfunction prefix

   subroutine print_message(self, msg, root_only)
   !< Print a message on stdout with the rank prefix.
   class(mpih_object), intent(in)           :: self      !< MPI handler.
   character(*),       intent(in)           :: msg       !< Message.
   logical,            intent(in), optional :: root_only !< Print on rank 0 only (default .false.).

   if (present(root_only)) then
      if (root_only .and. .not.self%is_root()) return
   endif
   write(stdout, '(A)') self%prefix()//trim(adjustl(msg))
   endsubroutine print_message

   subroutine warning(self, msg, root_only)
   !< Print a warning on stderr with the rank prefix.
   class(mpih_object), intent(in)           :: self      !< MPI handler.
   character(*),       intent(in)           :: msg       !< Message.
   logical,            intent(in), optional :: root_only !< Print on rank 0 only (default .false.).

   if (present(root_only)) then
      if (root_only .and. .not.self%is_root()) return
   endif
   write(stderr, '(A)') self%prefix()//'warning: '//trim(adjustl(msg))
   endsubroutine warning

   subroutine tic(self, name, sync)
   !< Start a timer: the named one of `timer` (created at its first `tic`), or the anonymous one without a name.
   class(mpih_object), intent(inout)        :: self !< MPI handler.
   character(*),       intent(in), optional :: name !< Timer name (default: the anonymous timer).
   logical,            intent(in), optional :: sync !< Barrier on `comm` first (default .false.).

   if (present(name)) then
      call self%timer%start(name=name, sync=sync)
   else
      call self%timer%start(name=ANONYMOUS_TIMER, sync=sync)
   endif
   endsubroutine tic

   pure function tictoc_timing(self) result(timing)
   !< Return the seconds between the two last timed barriers (`barrier(tictoc=.true.)`).
   class(mpih_object), intent(in) :: self   !< MPI handler.
   real(R8P)                      :: timing !< Seconds between the two clocks.

   timing = abs(self%timing(2) - self%timing(1))
   endfunction tictoc_timing

   function toc(self, name, sync) result(timing)
   !< Stop a timer and return the seconds from its `tic` (0 if it was not started); the interval is added to the
   !< timer's total, which `timer%report` reduces over the ranks.
   class(mpih_object), intent(inout)        :: self   !< MPI handler.
   character(*),       intent(in), optional :: name   !< Timer name (default: the anonymous timer).
   logical,            intent(in), optional :: sync   !< Barrier on `comm` first (default .false.).
   real(R8P)                                :: timing !< Seconds from the `tic`.

   if (present(name)) then
      timing = self%timer%stop(name=name, sync=sync)
   else
      timing = self%timer%stop(name=ANONYMOUS_TIMER, sync=sync)
   endif
   endfunction toc

   ! private non TBP
   subroutine die(self, msg, error_code)
   !< Print the message, abort every rank, stop with exit status 1 (the fatal path of `error_stop` and `abort`).
   class(mpih_object), intent(inout) :: self       !< MPI handler.
   character(*),       intent(in)    :: msg        !< Message.
   integer(I4P),       intent(in)    :: error_code !< Error code handed to the launcher.
   integer(C_INT)                    :: cerr       !< usleep status.

   self%error = error_code
   write(stderr, '(A)') self%prefix()//msg
   flush(stderr)
   flush(stdout)
   if (hmpi_is_active()) then
      cerr = c_usleep(500000_C_INT)
      call hmpi_abort(error_code)
   endif
   stop 1
   endsubroutine die
endmodule herald_mpih_object
