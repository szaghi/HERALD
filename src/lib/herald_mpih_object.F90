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
use            :: herald_kinds,    only : I4P
use            :: herald_mpi
use            :: herald_strings,  only : str, strz
implicit none
private
public :: mpih_object

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
   logical                   :: is_initialized=.false.     !< `initialize` ran: later calls return at once.
   logical                   :: owns_mpi=.false.           !< `initialize` initialized MPI: `finalize` finalizes it.
   contains
      procedure, pass(self) :: abort         !< Stop every rank with an error code and an optional message.
      procedure, pass(self) :: barrier       !< Block until every rank of `comm` has called it.
      procedure, pass(self) :: description   !< Return a pretty-printed description of the handler.
      procedure, pass(self) :: error_stop    !< Stop every rank with an error message, exit status 1.
      procedure, pass(self) :: finalize      !< Free the handler, and finalize MPI if the handler initialized it.
      procedure, pass(self) :: initialize    !< Initialize the handler (once), and MPI if nobody has.
      procedure, pass(self) :: is_root       !< Return true on rank 0 of `comm`.
      procedure, pass(self) :: prefix        !< Return the rank prefix of the messages (empty before `initialize`).
      procedure, pass(self) :: print_message !< Print a message on stdout with the rank prefix.
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

   subroutine barrier(self)
   !< Block until every rank of `comm` has called it (collective).
   class(mpih_object), intent(in) :: self !< MPI handler.

   call hmpi_barrier(self%comm)
   endsubroutine barrier

   pure function description(self) result(desc)
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
   desc = desc//p//'  node procs_number: '//str(self%node_procs_number)
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
   if (do_mpi_finalize_) call hmpi_stop
   self%is_initialized = .false.
   self%owns_mpi = .false.
   endsubroutine finalize

   subroutine initialize(self, comm, do_mpi_init, myrankstr_char_length, verbose)
   !< Initialize the handler (once), and MPI if nobody has.
   !<
   !< Once-only: a later call returns at once, so that every layer of a program (application, library, test driver) can
   !< call it without repeating the work or leaking a communicator (ADAM issue #80). MPI is initialized on demand, with
   !< the floating-point traps off (see `hmpi_start`); `do_mpi_init=.false.` states that the caller has done it, and
   !< the run stops if it has not.
   class(mpih_object), intent(inout)        :: self                   !< MPI handler.
   integer(I4P),       intent(in), optional :: comm                   !< Communicator (default: all the ranks).
   logical,            intent(in), optional :: do_mpi_init            !< Initialize MPI if nobody has (default .true.).
   integer(I4P),       intent(in), optional :: myrankstr_char_length  !< Digits of the rank in the prefix (default 5).
   logical,            intent(in), optional :: verbose                !< Print the description (default .false.).
   logical                                  :: do_mpi_init_           !< Initialize MPI, local variable.
   integer(I4P)                             :: myrankstr_char_length_ !< Digits of the rank, local variable.
   logical                                  :: verbose_               !< Print the description, local variable.

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
