!< HERALD, the MPI layer: the only module that uses MPI, or stands in for it in a serial build.
module herald_mpi
!< HERALD, the MPI layer: the only module that uses MPI, or stands in for it in a serial build.
!<
!< Every other module of HERALD calls these procedures and is free of preprocessor directives. Built with
!< `-DHERALD_NO_MPI` there is no MPI library: one rank, rank 0, communicators are plain integers, the reductions return
!< their input, the clock is `system_clock`.
!<
!< The names start with `hmpi_`, never with `mpi_`: MPI reserves that prefix.
#ifndef HERALD_NO_MPI
use :: mpi
#endif
use, intrinsic :: ieee_exceptions, only : ieee_get_halting_mode, ieee_set_halting_mode, ieee_usual
use            :: herald_kinds,    only : I4P, I8P, R8P
implicit none
private
public :: HERALD_CLOCK_MPI
public :: HERALD_CLOCK_SYSTEM
public :: HERALD_COMM_NULL
public :: HERALD_COMM_WORLD
public :: HERALD_HAS_MPI
public :: hmpi_abort
public :: hmpi_allgather_characters
public :: hmpi_barrier
public :: hmpi_free
public :: hmpi_is_active
public :: hmpi_rank
public :: hmpi_reduce
public :: hmpi_size
public :: hmpi_split_node
public :: hmpi_start
public :: hmpi_stop
public :: hmpi_wtime

#ifndef HERALD_NO_MPI
logical,      parameter :: HERALD_HAS_MPI    = .true.         !< The library is built with MPI.
integer(I4P), parameter :: HERALD_COMM_WORLD = MPI_COMM_WORLD !< The communicator of all the ranks.
integer(I4P), parameter :: HERALD_COMM_NULL  = MPI_COMM_NULL  !< The null communicator.
#else
logical,      parameter :: HERALD_HAS_MPI    = .false.        !< The library is built without MPI.
integer(I4P), parameter :: HERALD_COMM_WORLD = 0_I4P          !< The communicator of the single rank.
integer(I4P), parameter :: HERALD_COMM_NULL  = -1_I4P         !< The null communicator.
#endif

integer(I4P), parameter :: HERALD_CLOCK_SYSTEM = 0_I4P !< `hmpi_wtime` read `system_clock`.
integer(I4P), parameter :: HERALD_CLOCK_MPI    = 1_I4P !< `hmpi_wtime` read `MPI_WTIME`.

contains
   subroutine hmpi_abort(error_code)
   !< Abort every rank of the run (`MPI_ABORT` on `MPI_COMM_WORLD`); return at once without MPI or outside its life.
   integer(I4P), intent(in) :: error_code !< Error code handed to the launcher.
#ifndef HERALD_NO_MPI
   integer(I4P)             :: ierr       !< MPI error status.

   if (hmpi_is_active()) call MPI_ABORT(MPI_COMM_WORLD, error_code, ierr)
#else
   if (error_code /= error_code) return ! serial build: nothing to abort
#endif
   endsubroutine hmpi_abort

   subroutine hmpi_allgather_characters(comm, mine, everyone)
   !< Gather one string per rank of `comm`, in rank order (collective).
   integer(I4P), intent(in)  :: comm         !< Communicator.
   character(*), intent(in)  :: mine         !< This rank's string.
   character(*), intent(out) :: everyone(0:) !< The strings of all the ranks, of the length of `mine`.
#ifndef HERALD_NO_MPI
   integer(I4P)              :: ierr         !< MPI error status.

   call MPI_ALLGATHER(mine, len(mine), MPI_CHARACTER, everyone, len(mine), MPI_CHARACTER, comm, ierr)
#else
   if (comm /= HERALD_COMM_NULL) everyone(0) = mine
#endif
   endsubroutine hmpi_allgather_characters

   subroutine hmpi_barrier(comm)
   !< Block until every rank of `comm` has called it (collective).
   integer(I4P), intent(in) :: comm !< Communicator.
#ifndef HERALD_NO_MPI
   integer(I4P)             :: ierr !< MPI error status.

   call MPI_BARRIER(comm, ierr)
#else
   if (comm /= comm) return ! serial build: nothing to wait for
#endif
   endsubroutine hmpi_barrier

   subroutine hmpi_free(comm)
   !< Free a communicator made by `hmpi_split_node`, and set it to the null one.
   integer(I4P), intent(inout) :: comm !< Communicator.
#ifndef HERALD_NO_MPI
   integer(I4P)                :: ierr !< MPI error status.

   if (comm /= MPI_COMM_NULL .and. hmpi_is_active()) call MPI_COMM_FREE(comm, ierr)
#endif
   comm = HERALD_COMM_NULL
   endsubroutine hmpi_free

   function hmpi_is_active() result(is_active)
   !< Return true between `MPI_INIT` and `MPI_FINALIZE`; always false without MPI.
   logical      :: is_active      !< MPI is initialized and not finalized.
#ifndef HERALD_NO_MPI
   logical      :: is_initialized !< MPI initialized.
   logical      :: is_finalized   !< MPI finalized.
   integer(I4P) :: ierr           !< MPI error status.

   call MPI_INITIALIZED(is_initialized, ierr)
   call MPI_FINALIZED(is_finalized, ierr)
   is_active = is_initialized .and. .not.is_finalized
#else
   is_active = .false.
#endif
   endfunction hmpi_is_active

   function hmpi_rank(comm) result(rank)
   !< Return this process' rank in `comm`.
   integer(I4P), intent(in) :: comm !< Communicator.
   integer(I4P)             :: rank !< Rank, 0 without MPI.
#ifndef HERALD_NO_MPI
   integer(I4P)             :: ierr !< MPI error status.

   call MPI_COMM_RANK(comm, rank, ierr)
#else
   rank = 0_I4P*comm
#endif
   endfunction hmpi_rank

   subroutine hmpi_reduce(comm, x, x_min, x_max, x_sum)
   !< Reduce a real array over the ranks of `comm`, element by element (collective): minimum, maximum and sum.
   integer(I4P), intent(in)  :: comm     !< Communicator.
   real(R8P),    intent(in)  :: x(:)     !< This rank's values.
   real(R8P),    intent(out) :: x_min(:) !< Minimum over the ranks.
   real(R8P),    intent(out) :: x_max(:) !< Maximum over the ranks.
   real(R8P),    intent(out) :: x_sum(:) !< Sum over the ranks.
#ifndef HERALD_NO_MPI
   integer(I4P)              :: ierr     !< MPI error status.

   call MPI_ALLREDUCE(x, x_min, size(x), MPI_DOUBLE_PRECISION, MPI_MIN, comm, ierr)
   call MPI_ALLREDUCE(x, x_max, size(x), MPI_DOUBLE_PRECISION, MPI_MAX, comm, ierr)
   call MPI_ALLREDUCE(x, x_sum, size(x), MPI_DOUBLE_PRECISION, MPI_SUM, comm, ierr)
#else
   if (comm /= HERALD_COMM_NULL) then
      x_min = x ; x_max = x ; x_sum = x
   endif
#endif
   endsubroutine hmpi_reduce

   function hmpi_size(comm) result(ranks)
   !< Return the number of ranks of `comm`.
   integer(I4P), intent(in) :: comm  !< Communicator.
   integer(I4P)             :: ranks !< Ranks, 1 without MPI.
#ifndef HERALD_NO_MPI
   integer(I4P)             :: ierr  !< MPI error status.

   call MPI_COMM_SIZE(comm, ranks, ierr)
#else
   ranks = 1_I4P + 0_I4P*comm
#endif
   endfunction hmpi_size

   subroutine hmpi_split_node(comm, node_comm)
   !< Split `comm` into the communicators of the ranks that share a node's memory (`MPI_COMM_TYPE_SHARED`; collective).
   integer(I4P), intent(in)  :: comm      !< Communicator.
   integer(I4P), intent(out) :: node_comm !< Node-local communicator: free it with `hmpi_free`.
#ifndef HERALD_NO_MPI
   integer(I4P)              :: ierr      !< MPI error status.

   call MPI_COMM_SPLIT_TYPE(comm, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, node_comm, ierr)
#else
   node_comm = comm
#endif
   endsubroutine hmpi_split_node

   subroutine hmpi_start(started)
   !< Initialize MPI if nobody has; `started` tells whether this call did it (who starts MPI stops it).
   !<
   !< `MPI_INIT` runs with the floating-point traps off, restored afterwards: Open MPI 5.0.11's hwloc initializes
   !< libxml2, which makes its NaN by an invalid operation, and a program built with traps on (gfortran
   !< `-ffpe-trap=invalid`) dies there of SIGFPE (measured, 2026-11-20).
   logical, intent(out) :: started                   !< This call initialized MPI.
#ifndef HERALD_NO_MPI
   logical              :: is_initialized            !< MPI initialized.
   logical              :: halting(size(ieee_usual)) !< Halting modes of the program.
   integer(I4P)         :: ierr                      !< MPI error status.

   started = .false.
   call MPI_INITIALIZED(is_initialized, ierr)
   if (is_initialized) return
   call ieee_get_halting_mode(ieee_usual, halting)
   call ieee_set_halting_mode(ieee_usual, .false.)
   call MPI_INIT(ierr)
   call ieee_set_halting_mode(ieee_usual, halting)
   started = .true.
#else
   started = .false.
#endif
   endsubroutine hmpi_start

   subroutine hmpi_stop()
   !< Finalize MPI if it is active.
#ifndef HERALD_NO_MPI
   logical      :: halting(size(ieee_usual)) !< Halting modes of the program.
   integer(I4P) :: ierr                      !< MPI error status.

   if (.not.hmpi_is_active()) return
   call ieee_get_halting_mode(ieee_usual, halting)
   call ieee_set_halting_mode(ieee_usual, .false.)
   call MPI_FINALIZE(ierr)
   call ieee_set_halting_mode(ieee_usual, halting)
#endif
   endsubroutine hmpi_stop

   function hmpi_wtime(clock) result(seconds)
   !< Return the wall-clock time in seconds: `MPI_WTIME` while MPI is active, `system_clock` otherwise.
   !<
   !< The two clocks have different origins: the difference of two readings means something only if both came from
   !< the same clock. `clock` tells which one answered (`HERALD_CLOCK_MPI` or `HERALD_CLOCK_SYSTEM`): a caller that
   !< keeps a reading across `MPI_INIT` or `MPI_FINALIZE` must compare the clocks before subtracting.
   integer(I4P), intent(out), optional :: clock       !< The clock that answered.
   real(R8P)                           :: seconds     !< Wall-clock time from the clock's own origin.
   integer(I8P)                        :: count, rate !< Clock count and counts per second.

   if (present(clock)) clock = HERALD_CLOCK_SYSTEM
#ifndef HERALD_NO_MPI
   if (hmpi_is_active()) then
      seconds = MPI_WTIME()
      if (present(clock)) clock = HERALD_CLOCK_MPI
      return
   endif
#endif
   call system_clock(count=count, count_rate=rate)
   seconds = real(count, R8P)/real(rate, R8P)
   endfunction hmpi_wtime
endmodule herald_mpi
