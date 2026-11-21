!< HERALD test: the readers of /proc and of the cgroup limits, on files written by the test.
program herald_test_memory_readers
!< HERALD test: the readers of /proc and of the cgroup limits, on files written by the test.
!<
!< A CI runner cannot reproduce a Slurm cgroup: the readers take their files as arguments, and the test writes, under
!< `herald_test_memory_readers.tmp/`, a meminfo, a status and three cgroup trees:
!<
!< - v1, as Slurm on medooza: the task cgroup unlimited (about 2**63), the step limited to 64 GB, the job to 128 GB:
!<   the limit is the tightest, 64 GB;
!< - v2: the leaf holds `max`, its parent 8 GB, the root nothing: 8 GB;
!< - v2 with no limit anywhere, and a missing membership file: -1.
use :: herald_kinds,         only : I4P, I8P
use :: herald_memory_object, only : read_cgroup_limit, read_meminfo, read_status
implicit none
character(*), parameter :: TMP='herald_test_memory_readers.tmp'   !< Directory of the files.
integer(I8P), parameter :: GB=1024_I8P**3                         !< Bytes of a gigabyte.
integer(I8P)            :: total, available                       !< Bytes.

call execute_command_line('rm -rf '//TMP//' && mkdir -p '//TMP//'/v1/memory/slurm/job_7/step_0/task_0 '// &
                          TMP//'/v2/user.slice/app.scope '//TMP//'/v2none/a/b')
! /proc/meminfo: keys in any order, MemAvailable present, then absent (old kernels: MemFree)
call write_file(TMP//'/meminfo', [character(40) :: 'MemFree:         1000 kB', 'MemTotal:       16384 kB', &
                                                    'MemAvailable:    8192 kB', 'MemTotalFake:      1 kB'])
call read_meminfo(total=total, available=available, meminfo_file=TMP//'/meminfo')
if (total /= 16384_I8P*1024 .or. available /= 8192_I8P*1024) call fail('meminfo with MemAvailable')
call write_file(TMP//'/meminfo_old', [character(40) :: 'MemTotal:       16384 kB', 'MemFree:         1000 kB'])
call read_meminfo(total=total, available=available, meminfo_file=TMP//'/meminfo_old')
if (total /= 16384_I8P*1024 .or. available /= 1000_I8P*1024) call fail('meminfo without MemAvailable')
call read_meminfo(total=total, available=available, meminfo_file=TMP//'/absent')
if (total /= -1_I8P .or. available /= -1_I8P) call fail('missing meminfo')
! /proc/self/status
call write_file(TMP//'/status', [character(40) :: 'Name:   herald', 'VmHWM:      2048 kB', 'VmRSS:      1024 kB'])
if (read_status(key='VmRSS', status_file=TMP//'/status') /= 1024_I8P*1024) call fail('VmRSS')
if (read_status(key='VmHWM', status_file=TMP//'/status') /= 2048_I8P*1024) call fail('VmHWM')
if (read_status(key='VmSwap', status_file=TMP//'/status') /= -1_I8P) call fail('missing key')
! cgroup v1, Slurm-like
call write_file(TMP//'/v1/cgroup', [character(60) :: '12:cpuset:/slurm/job_7', '5:cpu,memory:/slurm/job_7/step_0/task_0', &
                                                      '0::/ignored'])
call write_file(TMP//'/v1/memory/slurm/job_7/step_0/task_0/memory.limit_in_bytes', ['9223372036854771712'])
call write_file(TMP//'/v1/memory/slurm/job_7/step_0/memory.limit_in_bytes', ['68719476736'])
call write_file(TMP//'/v1/memory/slurm/job_7/memory.limit_in_bytes', ['137438953472'])
call write_file(TMP//'/v1/memory/memory.limit_in_bytes', ['9223372036854771712'])
if (read_cgroup_limit(cgroup_file=TMP//'/v1/cgroup', cgroup_root=TMP//'/v1') /= 64*GB) call fail('cgroup v1')
! cgroup v2
call write_file(TMP//'/v2/cgroup', ['0::/user.slice/app.scope'])
call write_file(TMP//'/v2/user.slice/app.scope/memory.max', ['max'])
call write_file(TMP//'/v2/user.slice/memory.max', ['8589934592'])
if (read_cgroup_limit(cgroup_file=TMP//'/v2/cgroup', cgroup_root=TMP//'/v2') /= 8*GB) call fail('cgroup v2')
! no limit, the root cgroup, no membership file
call write_file(TMP//'/v2none/cgroup', ['0::/a/b'])
call write_file(TMP//'/v2none/a/b/memory.max', ['max'])
if (read_cgroup_limit(cgroup_file=TMP//'/v2none/cgroup', cgroup_root=TMP//'/v2none') /= -1_I8P) call fail('no limit')
call write_file(TMP//'/v2none/cgroup_root', ['0::/'])
if (read_cgroup_limit(cgroup_file=TMP//'/v2none/cgroup_root', cgroup_root=TMP//'/v2none') /= -1_I8P) call fail('root')
if (read_cgroup_limit(cgroup_file=TMP//'/absent', cgroup_root=TMP//'/v2') /= -1_I8P) call fail('missing cgroup file')
call execute_command_line('rm -rf '//TMP)
print '(A)', 'herald_test_memory_readers: ok'
contains
   subroutine fail(msg)
   !< Stop with a message.
   character(*), intent(in) :: msg !< Message.

   print '(A)', 'herald_test_memory_readers: '//msg
   error stop 1
   endsubroutine fail

   subroutine write_file(file, lines)
   !< Write a text file.
   character(*), intent(in) :: file     !< File name.
   character(*), intent(in) :: lines(:) !< Lines.
   integer(I4P)             :: u, l     !< Unit, counter.

   open(newunit=u, file=file, status='replace', action='write')
   do l=1, size(lines)
      write(u, '(A)') trim(lines(l))
   enddo
   close(u)
   endsubroutine write_file
endprogram herald_test_memory_readers
