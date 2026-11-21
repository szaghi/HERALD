!< HERALD test: the numbers-to-strings helpers.
program herald_test_strings
!< HERALD test: the numbers-to-strings helpers.
use :: herald_kinds,   only : I4P, I8P, R8P
use :: herald_strings, only : str, strz
implicit none

call check(str(0_I4P), '0')
call check(str(-42_I4P), '-42')
call check(str(huge(1_I4P)), '2147483647')
call check(str(-huge(1_I8P)), '-9223372036854775807')
call check(str(1.5_R8P, decimals=2_I4P), '1.50')
call check(str(0.25_R8P, decimals=2_I4P), '0.25')
call check(str(-0.5_R8P, decimals=1_I4P), '-0.5')
call check(str(0._R8P, decimals=0_I4P), '0.')
call check(str(1234.5_R8P), '1.234500E+03')
call check(str(1.e20_R8P, decimals=2_I4P), '1.000000E+20')
call check(strz(7_I4P, 5_I4P), '00007')
call check(strz(123456_I4P, 5_I4P), '123456')
call check(strz(0_I4P, 1_I4P), '0')
print '(A)', 'herald_test_strings: ok'
contains
   subroutine check(got, expected)
   !< Stop if the two strings differ.
   character(*), intent(in) :: got      !< String obtained.
   character(*), intent(in) :: expected !< String expected.

   if (got /= expected .or. len(got) /= len(expected)) then
      print '(A)', 'herald_test_strings: got "'//got//'", expected "'//expected//'"'
      error stop 1
   endif
   endsubroutine check
endprogram herald_test_strings
