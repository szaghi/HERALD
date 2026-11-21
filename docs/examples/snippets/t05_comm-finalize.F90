call half%finalize  ! frees the half's node communicator; MPI lives on
call world%finalize ! finalizes MPI
