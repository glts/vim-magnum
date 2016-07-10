" This is the XORSHIFT-ADD algorithm as presented by Mutsuo Saito and Makoto
" Matsumoto at http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/XSADD/.
"
" Copyright (c) 2014
" Mutsuo Saito, Makoto Matsumoto, Manieth Corp., and Hiroshima University.
" All rights reserved.
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.

" Note that this implementation was originally written for (and remains
" compatible with) Vim with 32-bit integers. See ":h +num64".
let s:BITS = 32

if has('num64')
  let s:NUM64_MASK = 0x100000000
endif

" Powers of two.
let s:POW2 = [0x1, 0x2, 0x4, 0x8,
    \ 0x10, 0x20, 0x40, 0x80,
    \ 0x100, 0x200, 0x400, 0x800,
    \ 0x1000, 0x2000, 0x4000, 0x8000,
    \ 0x10000, 0x20000, 0x40000, 0x80000,
    \ 0x100000, 0x200000, 0x400000, 0x800000,
    \ 0x1000000, 0x2000000, 0x4000000, 0x8000000,
    \ 0x10000000, 0x20000000, 0x40000000, 0x80000000,
    \ ]

let s:STATE = [0, 0, 0, 0]

let s:LOOP = 8

" Bitwise xors the Vim numbers a and b and returns the result.
if exists('*xor')
  function! s:BitXor(a, b) abort
    return xor(a:a, a:b)
  endfunction
else
  function! s:BitXor(a, b) abort
    let l:a = a:a
    let l:b = a:b
    let l:ret = 0
    for i in range(s:BITS)
      let l:ret += l:ret
      if l:a < 0 && l:b >= 0 || l:a >= 0 && l:b < 0
        let l:ret += 1
      endif
      let l:a += l:a
      let l:b += l:b
    endfor
    return l:ret
  endfunction
endif

" Bitwise left-shifts number x by b bits and returns the result. This function
" assumes that 0 < b < 32.
if has('num64')
  function! s:BitLsh(x, b) abort
    return (a:x * s:POW2[a:b]) % s:NUM64_MASK
  endfunction
else
  function! s:BitLsh(x, b) abort
    return a:x * s:POW2[a:b]
  endfunction
endif

" Performs an unsigned bitwise right-shift on x by b bits and returns the
" result. Assumes that 0 < b < 32.
if has('num64')
  function! s:BitRsh(x, b) abort
    return a:x / s:POW2[a:b]
  endfunction
else
  function! s:BitRsh(x, b) abort
    if a:x < 0
      return s:POW2[s:BITS-a:b-1] + (0x80000000 + a:x) / s:POW2[a:b]
    else
      return a:x / s:POW2[a:b]
    endif
  endfunction
endif

" Advances the random number generator to the next state.
function! s:XsaddNextState() abort
  let l:t = s:STATE[0]
  let l:t = s:BitXor(l:t, s:BitLsh(l:t, 15))
  let l:t = s:BitXor(l:t, s:BitRsh(l:t, 18))
  let l:t = s:BitXor(l:t, s:BitLsh(s:STATE[3], 11))
  let s:STATE = [s:STATE[1], s:STATE[2], s:STATE[3], l:t]
endfunction

" Initialises the random number generator state with the given seed.
function! s:XsaddInit(seed) abort
  let s:STATE = [a:seed, 0, 0, 0]
  for i in range(1, s:LOOP - 1)
    let l:prevstate = s:STATE[(i - 1) % 4]
    let l:newstate = 1812433253 * s:BitXor(l:prevstate, s:BitRsh(l:prevstate, 30))
    if has('num64')
      let l:newstate = l:newstate % s:NUM64_MASK
    endif
    let s:STATE[i % 4] = s:BitXor(s:STATE[i % 4], l:newstate + i)
  endfor
  " No need for the 'period certification' as no seed does produce [0, 0, 0, 0].
  for i in range(s:LOOP)
    call s:XsaddNextState()
  endfor
  " s:STATE is returned just for testing purposes. This is acceptable because
  " it doesn't cause any real trouble with performance or encapsulation.
  return s:STATE
endfunction

" Produces the next pseudo-random number from the random number generator.
function! s:XsaddNextInt() abort
  call s:XsaddNextState()
  if has('num64')
    return (s:STATE[3] + s:STATE[2]) % s:NUM64_MASK
  else
    return s:STATE[3] + s:STATE[2]
  endif
endfunction

" Returns true if the magnitude (digit list) x is less than the magnitude
" limit, false otherwise. The magnitudes must be of equal length.
function! s:IsInRange(limit, x) abort
  for i in range(len(a:limit)-1, 0, -1)
    if a:limit[i] != a:x[i]
      return a:limit[i] > a:x[i]
    endif
  endfor
  return 0
endfunction

" Removes trailing zeros in magnitude dg. Similar to the function in magnum.vim
" but simpler, since it is unlikely that the loop is entered more than once.
function! s:TrimZeros(dg) abort
  while !empty(a:dg) && a:dg[-1] == 0
    call remove(a:dg, -1)
  endwhile
  return a:dg
endfunction

" Returns a new, randomly generated Integer between zero inclusive and val
" exclusive.
function! s:NextInt(val) abort
  " magnum#Int(0) is a hack. As there is no way to access the s:NewInt factory
  " from this script, just use the public constructor to create the result
  " Integer. Initially, l:ret should be a new (no copy), non-negative Integer.
  let l:ret = magnum#Int(0)
  let l:dg = copy(a:val._dg)
  let l:nbits = 1
  while a:val._dg[-1] >= s:POW2[l:nbits]
    let l:nbits += 1
  endwhile
  while 1
    for i in range(len(a:val._dg) - 1)
      let l:dg[i] = s:BitRsh(s:XsaddNextInt(), 18)
    endfor
    let l:dg[-1] = s:BitRsh(s:XsaddNextInt(), s:BITS - l:nbits)
    if s:IsInRange(a:val._dg, l:dg)
      let l:ret._dg = s:TrimZeros(l:dg)
      return l:ret
    endif
  endwhile
endfunction

" This check duplicates the one in magnum.vim.
function! s:EnsureIsInt(val) abort
  if type(a:val) == type({}) && has_key(a:val, '_dg')
    return a:val
  endif
  throw 'magnum: Argument of magnum#random#NextInt must be Integer'
endfunction

function! magnum#random#NextInt(arg, ...) abort
  let l:arg = s:EnsureIsInt(a:arg)
  if empty(a:000)
    if l:arg.IsPositive()
      return s:NextInt(l:arg)
    endif
    throw printf('magnum: Expected positive Integer, got %s', l:arg.String())
  endif
  let l:limit = s:EnsureIsInt(a:1)
  if l:arg.Cmp(l:limit) < 0
    return l:arg.Add(s:NextInt(l:limit.Sub(l:arg)))
  endif
  throw printf('magnum: Invalid range %s..%s', l:arg.String(), l:limit.String())
endfunction

" Resets the state of the random number generator to the state obtained from
" the given number, which must be a Vim number. Only the least significant 32
" bits are used, to ensure same functionality with and without "+num64".
function! magnum#random#SetSeed(number) abort
  if type(a:number) != type(0)
    throw 'magnum: Argument of magnum#random#SetSeed must be number'
  endif
  call s:XsaddInit(has('num64') ? (a:number % s:NUM64_MASK) : a:number)
endfunction

" Seed using shuffled time and pid. Nothing serious, but given the range of
" values returned by these functions at least it seems like a fair try.
let s:seed = s:BitXor(localtime(), s:BitLsh(localtime(), 19))
if has('reltime')
  let s:seed = s:BitXor(s:seed, s:BitXor(reltime()[1], s:BitLsh(reltime()[1], 11)))
endif
let s:seed = s:BitXor(s:seed, s:BitLsh(getpid(), 13))
call s:XsaddInit(s:seed)
unlet s:seed
