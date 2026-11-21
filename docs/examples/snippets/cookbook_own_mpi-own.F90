call MPI_INIT(ierr)                        ! the program's, or a library's that came first
call mpih%initialize(do_mpi_init=.false.)  ! states that MPI is there: the run stops if it is not
if (mpih%is_root()) print '(A,L1)', 'the handler owns MPI: ', mpih%owns_mpi
call mpih%finalize                         ! MPI lives on
call MPI_FINALIZE(ierr)
