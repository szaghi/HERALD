!< HERALD, numbers to strings: the library's own helpers (HERALD has no dependencies).
module herald_strings
!< HERALD, numbers to strings: the library's own helpers (HERALD has no dependencies).
use :: herald_kinds, only : I4P, I8P, R8P
implicit none
private
public :: str
public :: strz

interface str
   !< Number to string, with no leading or trailing blanks.
   module procedure str_I4P, str_I8P, str_R8P
endinterface str

contains
   pure function str_I4P(n) result(s)
   !< Integer (I4P) to string.
   integer(I4P), intent(in)  :: n      !< Number.
   character(:), allocatable :: s      !< String.
   character(11)             :: buffer !< Buffer: sign and 10 digits.

   write(buffer, '(I0)') n
   s = trim(buffer)
   endfunction str_I4P

   pure function str_I8P(n) result(s)
   !< Integer (I8P) to string.
   integer(I8P), intent(in)  :: n      !< Number.
   character(:), allocatable :: s      !< String.
   character(20)             :: buffer !< Buffer: sign and 19 digits.

   write(buffer, '(I0)') n
   s = trim(buffer)
   endfunction str_I8P

   pure function str_R8P(x, decimals) result(s)
   !< Real (R8P) to string: fixed notation with `decimals` digits after the point when given (and the number fits),
   !< else scientific notation with 6 digits.
   real(R8P),    intent(in)           :: x        !< Number.
   integer(I4P), intent(in), optional :: decimals !< Digits after the decimal point, in [0, 15].
   character(:), allocatable          :: s        !< String.
   character(32)                      :: buffer   !< Buffer.
   character(16)                      :: fmt      !< Format.

   if (present(decimals)) then
      if (decimals >= 0 .and. decimals <= 15 .and. abs(x) < 1.e15_R8P) then
         write(fmt, '(A,I0,A)') '(F0.', decimals, ')'
         write(buffer, fmt) x
         s = trim(adjustl(buffer))
         if (s(1:1) == '.') s = '0'//s        ! F0.d drops the zero before the point
         if (len(s) > 1) then
            if (s(1:2) == '-.') s = '-0'//s(2:)
         endif
         return
      endif
   endif
   write(buffer, '(ES13.6E2)') x
   s = trim(adjustl(buffer))
   endfunction str_R8P

   pure function strz(n, width) result(s)
   !< Non-negative integer to string, padded with zeros on the left to `width` characters (wider numbers are not cut).
   integer(I4P), intent(in)  :: n      !< Number.
   integer(I4P), intent(in)  :: width  !< Minimum width.
   character(:), allocatable :: s      !< String.

   s = str(n)
   if (n >= 0 .and. len(s) < width) s = repeat('0', width - len(s))//s
   endfunction strz
endmodule herald_strings
