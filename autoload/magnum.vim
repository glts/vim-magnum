" magnum.vim - Pure Vim script big integer library
" Author: David Bürgin <dbuergin@gluet.ch>
" Version: 2.1.1
" Date: 2019-11-12
"
" The code in this library uses standard algorithms. I relied heavily on the
" descriptions in the book 'BigNum math' (Syngress, 2006) and the accompanying
" C library by Tom St Denis. I also used the references cited there.
"
" In the design of the API the goal was to present a picture of immutability
" to the user. Integer objects must appear immutable, and all operators must
" return further immutable Integers.
"
" In internal APIs however, Integers may be altered directly for efficiency.
" It is vital not to let a mutation of an 'immutable' escape! For example, we
" must be careful not to pass around magnum#ZERO and then mutate its
" internals. For the internal APIs a comment describes whether they return a
" copy or mutate in place.
"
" Vim script is not well suited for the task of implementing big integers. It
" doesn't have suitable unsigned integer types, nor sufficient support for
" bitwise operations. In the implementation we instead rely a lot on basic
" arithmetic such as x*2, or x%(2^14). We choose base 16384 (2^14).
"
" The code adopts some conventions (variable names, helper functions) from the
" book. There is little commentary, but comments are used where there is
" substantial difference from the book.

let s:BASE = 16384
let s:BITS = 14

" Powers of 2 up to s:BASE. These are used to implement bit shifting.
let s:POW2 = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384]

" Digit limit for Comba multiplication and squaring.
" TODO With "+num64" enabled the Comba limit can probably be much higher.
let s:COMBA_MAX_DIGITS = 8

" Alphanumeric digits used in string representations.
let s:DIGITS = '0123456789abcdefghijklmnopqrstuvwxyz'

function! s:EnsureIsInt(val, funcname) abort
  if type(a:val) == type({}) && has_key(a:val, '_dg')
    return a:val
  endif
  throw printf('magnum: Argument of Integer.%s must be Integer', a:funcname)
endfunction

" Returns true if this Integer is the value zero, false otherwise.
function! magnum#IsZero() dict abort
  return empty(self._dg)
endfunction

" Returns true if this Integer is positive, false otherwise.
function! magnum#IsPositive() dict abort
  return !self._neg && !self.IsZero()
endfunction

" Returns true if this Integer is negative, false otherwise.
function! magnum#IsNegative() dict abort
  return self._neg
endfunction

" Returns true if this Integer is even, false otherwise.
function! magnum#IsEven() dict abort
  return self.IsZero() || self._dg[0] % 2 == 0
endfunction

" Returns true if this Integer is odd, false otherwise.
function! magnum#IsOdd() dict abort
  return !self.IsZero() && self._dg[0] % 2 == 1
endfunction

" Returns true if this Integer is equal to val, false otherwise.
function! magnum#Eq(val) dict abort
  call s:EnsureIsInt(a:val, 'Eq')
  return self._neg == a:val._neg && self._dg == a:val._dg
endfunction

" Returns -1, 0, 1, depending on whether the magnitude of Integer a is less
" than, equal, greater than the magnitude of Integer b.
function! s:Compare(a, b) abort
  if len(a:a._dg) > len(a:b._dg)
    return 1
  elseif len(a:a._dg) < len(a:b._dg)
    return -1
  endif
  for i in range(len(a:a._dg)-1, 0, -1)
    if a:a._dg[i] > a:b._dg[i]
      return 1
    elseif a:a._dg[i] < a:b._dg[i]
      return -1
    endif
  endfor
  return 0
endfunction

" Returns -1, 0, 1 when this Integer is less than, equal, greater than val.
function! magnum#Cmp(val) dict abort
  call s:EnsureIsInt(a:val, 'Cmp')
  if self._neg && !a:val._neg
    return -1
  elseif !self._neg && a:val._neg
    return 1
  elseif self._neg
    return s:Compare(a:val, self)
  else
    return s:Compare(self, a:val)
  endif
endfunction

" Returns the absolute value of this Integer, |x|.
function! magnum#Abs() dict abort
  return s:NewInt(self._dg, 0)
endfunction

" Returns the negated value of this Integer, -x.
function! magnum#Neg() dict abort
  return self.IsZero() ? self : s:NewInt(self._dg, !self._neg)
endfunction

" Removes trailing zeros in the magnitude of Integer x. This is necessary when
" the Integer has ended up in a non-canonical form. Mutates x in place.
function! s:TrimZeros(x) abort
  let l:dg = a:x._dg
  if !empty(l:dg) && l:dg[-1] == 0
    let i = len(l:dg) - 2
    while i >= 0 && l:dg[i] == 0
      let i -= 1
    endwhile
    call remove(l:dg, i-len(l:dg)+1, -1)
  endif
  if empty(l:dg) && a:x._neg
    let a:x._neg = 0
  endif
  return a:x
endfunction

" Returns a new non-negative Integer that is the sum of Integers a and b.
" Ignores the signs of the Integers.
function! s:Add(a, b) abort
  if len(a:a._dg) > len(a:b._dg)
    let l:min = len(a:b._dg)
    let l:max = len(a:a._dg)
    let l:x = a:a._dg
  else
    let l:min = len(a:a._dg)
    let l:max = len(a:b._dg)
    let l:x = a:b._dg
  endif
  " Copy the bigger list. The values aren't actually needed, this is just an
  " efficient way to create a new list of length l:max.
  let l:dg = copy(l:x)
  let l:u = 0
  for i in range(l:min)
    let l:tmp = a:a._dg[i] + a:b._dg[i] + l:u
    let l:dg[i] = l:tmp % s:BASE
    let l:u = l:tmp / s:BASE
  endfor
  if l:min != l:max
    for i in range(l:min, l:max-1)
      let l:tmp = l:x[i] + l:u
      let l:dg[i] = l:tmp % s:BASE
      let l:u = l:tmp / s:BASE
    endfor
  endif
  if l:u > 0
    call add(l:dg, l:u)
  endif
  return s:NewInt(l:dg, 0)
endfunction

" Returns a new non-negative Integer that is the difference obtained by
" subtracting b from a. Assumes that |a| >= |b|, and ignores the signs.
function! s:Sub(a, b) abort
  let l:min = len(a:b._dg)
  let l:max = len(a:a._dg)
  let l:dg = copy(a:a._dg)
  let l:u = 0
  " This is different from the book algorithm, since we have neither bit
  " shifting and masking operations nor an unsigned int type at our disposal.
  for i in range(l:min)
    let l:tmp = a:a._dg[i] - a:b._dg[i] - l:u
    " Instead of masking we use the complement, s:BASE - |l:tmp|.
    let l:dg[i] = l:tmp < 0 ? s:BASE + l:tmp : l:tmp
    let l:u = l:tmp < 0
  endfor
  if l:min != l:max
    for i in range(l:min, l:max-1)
      let l:tmp = a:a._dg[i] - l:u
      let l:dg[i] = l:tmp < 0 ? s:BASE + l:tmp : l:tmp
      let l:u = l:tmp < 0
    endfor
  endif
  let l:ret = s:NewInt(l:dg, 0)
  return s:TrimZeros(l:ret)
endfunction

" Returns the sum of this Integer and val.
function! magnum#Add(val) dict abort
  call s:EnsureIsInt(a:val, 'Add')
  if self._neg == a:val._neg
    let l:ret = s:Add(self, a:val)
    let l:ret._neg = self._neg
  else
    if s:Compare(self, a:val) < 0
      let l:ret = s:Sub(a:val, self)
      let l:ret._neg = a:val._neg
    else
      " This is the only case that may result in negative zero.
      let l:ret = s:Sub(self, a:val)
      let l:ret._neg = empty(l:ret._dg) ? 0 : self._neg
    endif
  endif
  return l:ret
endfunction

" Returns the difference of this Integer and val.
function! magnum#Sub(val) dict abort
  call s:EnsureIsInt(a:val, 'Sub')
  if self._neg != a:val._neg
    let l:ret = s:Add(self, a:val)
    let l:ret._neg = self._neg
  else
    if s:Compare(self, a:val) >= 0
      " This is the only case that may result in negative zero.
      let l:ret = s:Sub(self, a:val)
      let l:ret._neg = empty(l:ret._dg) ? 0 : self._neg
    else
      let l:ret = s:Sub(a:val, self)
      let l:ret._neg = !self._neg
    endif
  endif
  return l:ret
endfunction

" Returns a new non-negative Integer that is the product of Integers a and b.
" Ignores the signs of the Integers.
function! s:MulBasic(a, b) abort
  let l:lena = len(a:a._dg)
  let l:lenb = len(a:b._dg)
  let l:dg = repeat([0], l:lena + l:lenb)
  for i in range(l:lena)
    let l:u = 0
    for j in range(l:lenb)
      let l:tmp = l:dg[i+j] + a:a._dg[i] * a:b._dg[j] + l:u
      let l:dg[i+j] = l:tmp % s:BASE
      let l:u = l:tmp / s:BASE
    endfor
    let l:dg[i+l:lenb] = l:u
  endfor
  let l:ret = s:NewInt(l:dg, 0)
  return s:TrimZeros(l:ret)
endfunction

" Returns a new non-negative Integer that is the product of Integers a and b.
" Ignores the signs. This is the faster but size-limited Comba algorithm.
function! s:MulComba(a, b) abort
  let l:lena = len(a:a._dg)
  let l:lenb = len(a:b._dg)
  let l:dg = repeat([0], l:lena + l:lenb)
  let l:w = 0
  for i in range(l:lena + l:lenb)
    let l:tb = l:lenb-1 < i ? l:lenb-1 : i
    let l:ta = i - l:tb
    for k in range(l:lena-l:ta < l:tb+1 ? l:lena-l:ta : l:tb+1)
      let l:w += a:a._dg[l:ta+k] * a:b._dg[l:tb-k]
    endfor
    let l:dg[i] = l:w % s:BASE
    let l:w = l:w / s:BASE
  endfor
  let l:ret = s:NewInt(l:dg, 0)
  return s:TrimZeros(l:ret)
endfunction

" Returns the product of this Integer and val.
function! magnum#Mul(val) dict abort
  call s:EnsureIsInt(a:val, 'Mul')
  let l:min = len(self._dg) < len(a:val._dg) ? len(self._dg) : len(a:val._dg)
  if l:min <= s:COMBA_MAX_DIGITS
    let l:ret = s:MulComba(self, a:val)
  else
    let l:ret = s:MulBasic(self, a:val)
  endif
  if !empty(l:ret._dg)
    let l:ret._neg = self._neg != a:val._neg
  endif
  return l:ret
endfunction

" Left-shift Integer x by b digits. Equivalent to multiplication with
" s:BASE^b. This function assumes b >= 0, mutates x in place, ignores sign.
function! s:LshDigits(x, b) abort
  " Own algorithm: simply prepend b zeros to the magnitude.
  if a:b > 0 && !a:x.IsZero()
    call extend(a:x._dg, repeat([0], a:b), 0)
  endif
  return a:x
endfunction

" Right-shift Integer x by b digits. Equivalent to division by s:BASE^b.
" Assumes b >= 0, mutates x in place, ignores sign.
function! s:RshDigits(x, b) abort
  if a:b > 0 && !a:x.IsZero()
    if len(a:x._dg) > a:b
      call remove(a:x._dg, 0, a:b-1)
    else
      call remove(a:x._dg, 0, -1)
      let a:x._neg = 0
    endif
  endif
  return a:x
endfunction

" Left-shift Integer x by b (bits). Equivalent to multiplication with 2^b.
" Assumes b >= 0. Mutates x in place, and ignores the sign.
function! s:Lsh(x, b) abort
  " First shift by whole digits, then bit-shift by the remaining amount.
  if a:b >= s:BITS
    call s:LshDigits(a:x, a:b/s:BITS)
  endif
  let l:d = a:b % s:BITS
  if l:d != 0
    let l:mask = s:POW2[l:d]
    let l:invmask = s:POW2[s:BITS-l:d]
    let l:r = 0
    for i in range(len(a:x._dg))
      let l:tmp = a:x._dg[i] / l:invmask
      let a:x._dg[i] = (a:x._dg[i] * l:mask + l:r) % s:BASE
      let l:r = l:tmp
    endfor
    if l:r > 0
      call add(a:x._dg, l:r)
    endif
  endif
  return a:x
endfunction

" Right-shift Integer x by b. Equivalent to division by 2^b. Assumes b >= 0.
" Mutates x in place, ignores sign.
function! s:Rsh(x, b) abort
  if a:b >= s:BITS
    call s:RshDigits(a:x, a:b/s:BITS)
  endif
  let l:d = a:b % s:BITS
  if l:d != 0
    let l:mask = s:POW2[l:d]
    let l:invmask = s:POW2[s:BITS-l:d]
    let l:r = 0
    for i in range(len(a:x._dg)-1, 0, -1)
      let l:tmp = a:x._dg[i] % l:mask
      let a:x._dg[i] = (l:r * l:invmask) + (a:x._dg[i] / l:mask)
      let l:r = l:tmp
    endfor
  endif
  return s:TrimZeros(a:x)
endfunction

" Returns a new non-negative Integer that is the product of a and b. Here a is
" an Integer, and b is a single base s:BASE digit.
function! s:MulDigit(a, b) abort
  let l:dg = copy(a:a._dg)
  let l:u = 0
  for i in range(len(a:a._dg))
    let l:tmp = a:a._dg[i] * a:b + l:u
    let l:dg[i] = l:tmp % s:BASE
    let l:u = l:tmp / s:BASE
  endfor
  if l:u > 0
    call add(l:dg, l:u)
  endif
  let l:ret = s:NewInt(l:dg, 0)
  return s:TrimZeros(l:ret)
endfunction

" Divides Integer a by b and returns the resulting [quotient, remainder].
" Here b and remainder are single digits. Ignores sign of a, assumes b > 0.
function! s:DivRemDigit(a, b) abort
  " This is the result magnitude, use copy() for efficiency.
  let l:dg = copy(a:a._dg)
  let l:r = 0
  for i in range(len(a:a._dg)-1, 0, -1)
    let l:r = l:r * s:BASE + a:a._dg[i]
    if l:r >= a:b
      let l:dg[i] = l:r / a:b
      let l:r = l:r % a:b
    else
      let l:dg[i] = 0
    endif
  endfor
  let l:q = s:NewInt(l:dg, 0)
  call s:TrimZeros(l:q)
  return [l:q, l:r]
endfunction

" Divides Integer a by Integer b and returns the resulting pair of Integers
" [quotient, remainder]. This is the high-level signed division function.
function! s:DivRem(a, b) abort
  if a:b.IsZero()
    throw 'magnum: Division by zero'
  endif
  if s:Compare(a:a, a:b) < 0
    return [g:magnum#ZERO, a:a]
  endif
  if len(a:b._dg) == 1
    let [l:q, l:rd] = s:DivRemDigit(a:a, a:b._dg[0])
    let l:q._neg = a:a._neg != a:b._neg
    let l:r = s:NewInt(l:rd ? [l:rd] : [], a:a._neg)
    return [l:q, l:r]
  endif

  " Normalise Integers l:x and l:y, which serve as non-negative mutable
  " working copies of dividend and divisor.
  let l:x = s:NewInt(a:a._dg, 0)
  let l:y = s:NewInt(a:b._dg, 0)
  let l:norm = 0
  while l:y._dg[-1] < s:POW2[s:BITS-l:norm-1]
    let l:norm += 1
  endwhile
  call s:Lsh(l:x, l:norm)
  call s:Lsh(l:y, l:norm)

  " Produce the leading digit of the quotient result l:dg, if any.
  let l:n = len(l:x._dg) - 1
  let l:t = len(l:y._dg) - 1
  let l:dg = repeat([0], l:n-l:t+1)
  call s:LshDigits(l:y, l:n-l:t)
  if l:x.Cmp(l:y) >= 0
    let l:dg[l:n-l:t] += 1
    let l:x = l:x.Sub(l:y)
  endif
  call s:RshDigits(l:y, l:n-l:t)

  " Main loop. Produce the remaining digits of the quotient result.
  for i in range(l:n, l:t+1, -1)
    " First make the initial rough estimate for the current quotient digit.
    if i > len(l:x._dg)
      " Skip if i is out of bounds by two. This happens when the magnitude of
      " l:x has been reduced by several positions in the last iteration.
      continue
    endif
    let l:xi = len(l:x._dg) > i ? l:x._dg[i] : 0
    if l:xi == l:y._dg[l:t]
      let l:dg[i-l:t-1] = s:BASE - 1
    else
      let l:dg[i-l:t-1] = (l:xi * s:BASE + l:x._dg[i-1]) / l:y._dg[l:t]
    endif

    " Now make the quotient estimation accurate. Substitute zero for digits at
    " out-of-bounds indices.
    let l:tmpx = s:NewInt([(i-2 < 0 ? 0 : l:x._dg[i-2]), (i-1 < 0 ? 0 : l:x._dg[i-1]), l:xi], 0)
    let l:tmpy = s:NewInt([(l:t-1 < 0 ? 0 : l:y._dg[l:t-1]), l:y._dg[l:t]], 0)
    let l:qy = s:MulDigit(l:tmpy, l:dg[i-l:t-1])
    while s:Compare(l:qy, l:tmpx) > 0
      let l:dg[i-l:t-1] -= 1
      let l:qy = s:MulDigit(l:tmpy, l:dg[i-l:t-1])
    endwhile
    let l:qy = s:MulDigit(l:y, l:dg[i-l:t-1])
    call s:LshDigits(l:qy, i-l:t-1)
    let l:x = l:x.Sub(l:qy)
    if l:x._neg
      " If the subtraction has made l:x negative, the estimate for the current
      " quotient digit was one too large. Fix.
      let l:y1 = s:LshDigits(deepcopy(l:y), i-l:t-1)
      let l:x = l:x.Add(l:y1)
      let l:dg[i-l:t-1] -= 1
    endif
  endfor

  " Finalise the result pair. Shift the remainder back l:norm places.
  let l:q = s:NewInt(l:dg, a:a._neg != a:b._neg)
  call s:TrimZeros(l:q)
  let l:r = s:Rsh(l:x, l:norm)
  if !l:r.IsZero()
    let l:r._neg = a:a._neg
  endif
  return [l:q, l:r]
endfunction

" Returns the quotient of this Integer and val.
function! magnum#Div(val) dict abort
  call s:EnsureIsInt(a:val, 'Div')
  return s:DivRem(self, a:val)[0]
endfunction

" Returns the remainder obtained by dividing this Integer by val.
function! magnum#Rem(val) dict abort
  call s:EnsureIsInt(a:val, 'Rem')
  return s:DivRem(self, a:val)[1]
endfunction

" Returns the pair [quotient, remainder] obtained by dividing this Integer
" by val.
function! magnum#DivRem(val) dict abort
  call s:EnsureIsInt(a:val, 'DivRem')
  return s:DivRem(self, a:val)
endfunction

function! s:EnsureIsPositiveOrZeroExponent(number) abort
  if type(a:number) != type(0)
    throw 'magnum: Argument of Integer.Pow must be number'
  elseif a:number >= 0
    return a:number
  endif
  throw printf('magnum: Expected positive number or zero, got %d', a:number)
endfunction

" Returns a new Integer that is the square of Integer x.
function! s:SqrBasic(x) abort
  let l:lenx = len(a:x._dg)
  let l:dg = repeat([0], 2 * l:lenx)
  for i in range(l:lenx)
    let l:r = l:dg[2*i] + a:x._dg[i] * a:x._dg[i]
    let l:dg[2*i] = l:r % s:BASE
    let l:u = l:r / s:BASE
    for j in range(i+1, l:lenx-1)
      let l:r = l:dg[i+j] + 2 * a:x._dg[i] * a:x._dg[j] + l:u
      let l:dg[i+j] = l:r % s:BASE
      let l:u = l:r / s:BASE
    endfor
    let l:dg[i+l:lenx] = l:u
  endfor
  let l:ret = s:NewInt(l:dg, 0)
  return s:TrimZeros(l:ret)
endfunction

" Returns a new Integer that is the square of Integer x. Comba algorithm.
function! s:SqrComba(x) abort
  let l:lenx = len(a:x._dg)
  let l:dg = repeat([0], 2 * l:lenx)
  let l:w1 = 0
  for i in range(2 * l:lenx)
    let l:w = 0
    let l:ty = l:lenx-1 < i ? l:lenx-1 : i
    let l:tx = i - l:ty
    " Loop over 0...j-1, where j is min((l:ty-l:tx+1)/2, l:lenx-l:tx, l:ty+1).
    let j = l:lenx-l:tx < l:ty+1 ? l:lenx-l:tx : l:ty+1
    for k in range((l:ty-l:tx+1)/2 < j ? (l:ty-l:tx+1)/2 : j)
      let l:w += a:x._dg[l:tx+k] * a:x._dg[l:ty-k]
    endfor
    let l:w = 2 * l:w + l:w1
    if i % 2 == 0
      let l:w += a:x._dg[i/2] * a:x._dg[i/2]
    endif
    let l:dg[i] = l:w % s:BASE
    let l:w1 = l:w / s:BASE
  endfor
  let l:ret = s:NewInt(l:dg, 0)
  return s:TrimZeros(l:ret)
endfunction

" Returns a new Integer that is the square of Integer x (x^2).
function! s:Sqr(x) abort
  if len(a:x._dg) <= s:COMBA_MAX_DIGITS
    let l:ret = s:SqrComba(a:x)
  else
    let l:ret = s:SqrBasic(a:x)
  end
  return l:ret
endfunction

" Returns this Integer raised to the power of number. The argument is a Vim
" number, not an Integer.
function! magnum#Pow(number) dict abort
  let l:n = s:EnsureIsPositiveOrZeroExponent(a:number)
  let l:bits = []
  while l:n != 0
    call insert(l:bits, l:n % 2)
    let l:n = l:n / 2
  endwhile
  " Don't use magnum#ONE for l:ret, its _neg may be manipulated directly below.
  let l:ret = s:NewInt([1], 0)
  for l:bit in l:bits
    let l:ret = s:Sqr(l:ret)
    if l:bit
      let l:ret = l:ret.Mul(self)
    endif
  endfor
  if self._neg
    let l:ret._neg = a:number % 2
  endif
  return l:ret
endfunction

" Method prototype for Integers. Extracted from s:NewInt for efficiency.
let s:PROTO = {
    \ 'IsZero': function('magnum#IsZero'),
    \ 'IsPositive': function('magnum#IsPositive'),
    \ 'IsNegative': function('magnum#IsNegative'),
    \ 'IsEven': function('magnum#IsEven'),
    \ 'IsOdd': function('magnum#IsOdd'),
    \ 'Eq': function('magnum#Eq'),
    \ 'Cmp': function('magnum#Cmp'),
    \ 'Abs': function('magnum#Abs'),
    \ 'Neg': function('magnum#Neg'),
    \ 'Add': function('magnum#Add'),
    \ 'Sub': function('magnum#Sub'),
    \ 'Mul': function('magnum#Mul'),
    \ 'Div': function('magnum#Div'),
    \ 'Rem': function('magnum#Rem'),
    \ 'DivRem': function('magnum#DivRem'),
    \ 'Pow': function('magnum#Pow'),
    \ 'Number': function('magnum#Number'),
    \ 'String': function('magnum#String'),
    \ }

" Constructs a new Integer from magnitude dg and sign neg. This copies the
" (mutable) magnitude list dg, in order to prevent accidental sharing.
function! s:NewInt(dg, neg) abort
  " The internal representation of an Integer consists of two parts, the sign
  " _neg, which is true when the Integer is negative, and the magnitude list
  " _dg, which holds the digits of the Integer, least significant digit first.
  " Integer zero has the representation _dg = [] and _neg = 0.
  return extend({'_dg': copy(a:dg), '_neg': !empty(a:dg) && a:neg}, s:PROTO)
endfunction

function! s:EnsureIsBase(number) abort
  if type(a:number) != type(0)
    throw 'magnum: Base argument must be number'
  elseif 2 <= a:number && a:number <= 36
    return a:number
  endif
  throw printf('magnum: Expected base between 2 and 36, got %d', a:number)
endfunction

" Creates a new Integer from number.
function! s:NumberToInt(number) abort
  let l:neg = a:number < 0
  let l:number = l:neg ? a:number : -a:number
  let l:dg = []
  while l:number < 0
    call add(l:dg, -(l:number%s:BASE))
    let l:number = l:number / s:BASE
  endwhile
  return s:NewInt(l:dg, l:neg)
endfunction

" Valid number string patterns for all bases.
let s:NUMBER_STRING_PATTERNS = map(split(s:DIGITS[1:], '\zs'),
    \ '"^-\\=[" . (v:val =~# "\\d" ? "0-" : "0-9a-") . v:val . "]\\+$"')

" Ensures that string represents a number in the given base. This 'Ensure' is
" somewhat special in that it returns a different, lowercased string value.
function! s:EnsureIsNumberString(string, base) abort
  let l:string = tolower(a:string)
  if l:string =~# s:NUMBER_STRING_PATTERNS[a:base-2]
    return l:string
  endif
  throw printf('magnum: Invalid number of base %d: "%s"', a:base, a:string)
endfunction

" Parses an Integer from the string in the given base and returns it. This
" function assumes the string is a valid number string of the given base.
function! s:ParseInt(string, base) abort
  if a:string[0] ==# '-'
    let l:neg = 1
    let l:string = a:string[1:]
  else
    let l:neg = 0
    let l:string = a:string
  endif
  let l:ret = g:magnum#ZERO
  for i in range(len(l:string))
    let l:ret = s:MulDigit(l:ret, a:base)
    let l:d = stridx(s:DIGITS, l:string[i])
    let l:ret = l:ret.Add(s:NewInt(l:d ? [l:d] : [], 0))
  endfor
  if !l:ret.IsZero()
    let l:ret._neg = l:neg
  endif
  return l:ret
endfunction

" Returns a new Integer given a number or string argument. This is the public
" constructor for Integer objects.
function! magnum#Int(arg, ...) abort
  " The awkward control flow here is to present uncaught exceptions cleanly to
  " the user, and especially to avoid showing a misleading E171 error.
  if type(a:arg) == type(0)
    return s:NumberToInt(a:arg)
  elseif type(a:arg) != type('')
    throw 'magnum: Expected number or string argument'
  endif
  let l:base = s:EnsureIsBase(get(a:, 1, 10))
  let l:string = s:EnsureIsNumberString(a:arg, l:base)
  return s:ParseInt(l:string, l:base)
endfunction

if has('num64')
  let s:MIN_INT = magnum#Int(0x8000000000000000)
  let s:MAX_INT = magnum#Int(0x7fffffffffffffff)
else
  let s:MIN_INT = magnum#Int(0x80000000)
  let s:MAX_INT = magnum#Int(0x7fffffff)
endif

" Returns this Integer as a Vim number. This throws an overflow exception when
" the Integer doesn't fit in a number, which may be signed int32 or signed
" int64 depending on the machine.
function! magnum#Number() dict abort
  if self.Cmp(s:MIN_INT) >= 0 && self.Cmp(s:MAX_INT) <= 0
    let l:n = 0
    let l:b = 1
    " Do the accumulation in negative numbers.
    for l:digit in self._dg
      let l:n -= l:digit * l:b
      let l:b = l:b * s:BASE
    endfor
    return self._neg ? l:n : -l:n
  endif
  throw 'magnum: Integer overflow'
endfunction

" Returns this Integer as a string. The optional argument should be a number
" between 2 and 36 specifying the desired base.
function! magnum#String(...) dict abort
  let l:base = s:EnsureIsBase(get(a:, 1, 10))
  if self.IsZero()
    return '0'
  endif
  let l:q = self.Abs()
  let l:string = ''
  while !l:q.IsZero()
    let [l:q, l:r] = s:DivRemDigit(l:q, l:base)
    " Since we only support bases < s:BASE we can grab the digit directly.
    let l:string = s:DIGITS[l:r] . l:string
  endwhile
  return self._neg ? ('-' . l:string) : l:string
endfunction

" Constants

" Use :lockvar without the bang. This protects the constant reference from
" changing, but keeps the dicts open for extension (as for all Integers).
" :unlockvar is needed to allow resourcing of this script.
unlockvar magnum#ZERO magnum#ONE
let magnum#ZERO = s:NewInt([], 0)
let magnum#ONE = s:NewInt([1], 0)
lockvar magnum#ZERO magnum#ONE
