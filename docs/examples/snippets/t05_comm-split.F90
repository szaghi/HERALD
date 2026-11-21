color = mod(world%myrank, 2)
call MPI_COMM_SPLIT(world%comm, color, world%myrank, comm, ierr)
call half%initialize(comm=comm)
