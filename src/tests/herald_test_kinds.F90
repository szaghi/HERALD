!< HERALD test: the kinds of the library have the widths their names state.
program herald_test_kinds
!< HERALD test: the kinds of the library have the widths their names state.
use herald_kinds, only : I4P, I8P, R8P
implicit none

if (storage_size(1_I4P) /= 32)  error stop 'I4P is not a 32-bit integer'
if (storage_size(1_I8P) /= 64)  error stop 'I8P is not a 64-bit integer'
if (storage_size(1._R8P) /= 64) error stop 'R8P is not a 64-bit real'
if (kind(1.d0) /= R8P)          error stop 'R8P is not double precision (MPI_WTIME)'
print '(A)', 'herald_test_kinds: ok'
endprogram herald_test_kinds
