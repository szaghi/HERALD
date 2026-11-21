!< HERALD test: the memory budget of the rank and the memory the process uses, on the machine that runs the test.
program herald_test_memory_mpi
!< HERALD test: the memory budget of the rank and the memory the process uses, on the machine that runs the test.
!<
!< On Linux: the node's memory is known, the binding limit is the node's or the cgroup's and not larger than the
!< node's, the budget is the limit divided by the ranks on the node; the process uses some memory, its peak is not
!< smaller, and allocating and touching 64 MB raises both by about as much. One byte fits the budget; the budget plus
!< one byte does not. Where /proc is missing everything is unknown and every check passes.
use :: herald
use :: herald_kinds, only : I8P, R8P
implicit none
type(mpih_object)         :: mpih                !< The handler.
integer(I8P), parameter   :: MB=1024_I8P**2      !< Bytes of a megabyte.
integer(I8P)              :: used0, used1, peak1 !< Bytes.
real(R8P), allocatable    :: work(:)             !< Memory to touch.
logical                   :: is_ok               !< A number of bytes fits.
character(:), allocatable :: msg, text           !< Messages.

call mpih%initialize
associate(memory=>mpih%memory)
if (memory%node_total > 0_I8P) then
   if (memory%limit <= 0_I8P .or. memory%limit > memory%node_total) call fail('limit out of (0, node total]')
   if (memory%limit_source /= 'node' .and. memory%limit_source /= 'cgroup') call fail('source: '//memory%limit_source)
   if ((memory%limit_source == 'cgroup') .neqv. (memory%cgroup_limit > 0 .and. memory%cgroup_limit < memory%node_total)) &
      call fail('the binding limit is not the smaller one')
   if (memory%per_rank() /= memory%limit/mpih%node_procs_number) call fail('budget is not limit/node ranks')
   if (abs(mpih%memory_avail*1024._R8P**3 - real(memory%per_rank(), R8P)) > 1._R8P) call fail('memory_avail [GB]')
   used0 = memory%used()
   if (used0 <= 0_I8P .or. memory%peak() < used0) call fail('in use must be positive, and the peak not smaller')
   allocate(work(64*MB/8)) ; work = 1._R8P
   used1 = memory%used() ; peak1 = memory%peak()
   if (used1 - used0 < 48*MB .or. peak1 < used1) call fail('64 MB touched are not seen in VmRSS and VmHWM')
   if (sum(work) < 1._R8P) call fail('work')
   call memory%check(bytes_needed=1_I8P, is_ok=is_ok, msg=msg, what='one byte')
   if (.not.is_ok .or. index(msg, 'one byte') /= 1) call fail('one byte must fit: '//msg)
   call memory%check(bytes_needed=memory%per_rank() + 1_I8P, is_ok=is_ok, msg=msg)
   if (is_ok .or. index(msg, 'budget') == 0) call fail('the budget plus one byte must not fit: '//msg)
   call mpih%check_memory(bytes_needed=1_I8P, what='one byte')
else
   if (memory%limit_source /= 'unknown' .or. memory%per_rank() /= -1_I8P) call fail('unknown memory')
   call memory%check(bytes_needed=1024_I8P**5, is_ok=is_ok)
   if (.not.is_ok) call fail('an unknown budget always fits')
endif
text = memory%report_string()
if (index(text, 'peak') == 0 .or. index(text, 'budget') == 0) call fail('report: '//text)
if (index(mpih%description(), 'host memory') == 0) call fail('description without the memory')
endassociate
call mpih%print_message('herald_test_memory_mpi: ok', root_only=.true.)
call mpih%finalize
contains
   subroutine fail(msg)
   !< Stop every rank with a message.
   character(*), intent(in) :: msg !< Message.

   call mpih%error_stop(msg='herald_test_memory_mpi: '//msg)
   endsubroutine fail
endprogram herald_test_memory_mpi
