" Random number generator tests

" All Vim numbers that would be negative as signed 32-bit integers have been
" converted to their unsigned counterpart (same bit pattern). This is so that
" the tests work for Vim compiled with and without the "+num64" feature.

" Same as in t/internal.vim. Force sourcing of the autoload script for vspec.
runtime autoload/magnum/random.vim

function! SID() abort
  redir => l:scriptnames
  silent scriptnames
  redir END
  for line in split(l:scriptnames, '\n')
    let [l:sid, l:path] = matchlist(line, '^\s*\(\d\+\):\s*\(.*\)$')[1:2]
    if l:path =~# '\<autoload[/\\]magnum[/\\]random\.vim$'
      return '<SNR>' . l:sid . '_'
    endif
  endfor
endfunction
call vspec#hint({'sid': 'SID()'})

let g:MIN_INT32 = 0x80000000
let g:MAX_INT32 = 0x7fffffff

describe "Vim number arithmetic"
  it "passes basic sanity check"
    if has('num64')
      let min_int = 0x8000000000000000
      let max_int = 0x7fffffffffffffff
    else
      let min_int = g:MIN_INT32
      let max_int = g:MAX_INT32
    endif
    Expect min_int + 1 == -max_int
    Expect min_int + min_int == 0
    Expect min_int + min_int == 0
    Expect max_int + max_int == -2
  end
end

describe "s:BitXor"
  it "xors bits of two numbers"
    Expect Call('s:BitXor', 0, 0) == 0
    Expect Call('s:BitXor', 0, 1) == 1
    Expect Call('s:BitXor', 1, 0) == 1
    Expect Call('s:BitXor', 2, 0) == 2
    Expect Call('s:BitXor', 0, 3) == 3

    "   0011
    " ^ 1001
    Expect Call('s:BitXor', 3, 9) == 10

    "   00000000000000001101010011000111
    " ^ 11100010000100110111000111000001
    " = 11100010000100111010010100000110
    Expect Call('s:BitXor', 54471, 3792925121) == 3792938246

    "   11100000000000000000000000000000
    " ^ 00011111111111111111111111111111
    Expect Call('s:BitXor', 3758096384, 536870911) == 4294967295
  end

  it "handles numbers at boundaries correctly"
    "   01111111111111111111111111111111
    " ^ 00000000000000000000000000000000
    Expect Call('s:BitXor', g:MAX_INT32, 0) == g:MAX_INT32

    "   01111111111111111111111111111111
    " ^ 01111111111111111111111111111111
    Expect Call('s:BitXor', g:MAX_INT32, g:MAX_INT32) == 0

    "   01111111111111111111111111111111
    " ^ 11111111111111111111111111111111
    Expect Call('s:BitXor', g:MAX_INT32, 4294967295) == g:MIN_INT32

    "   00000000000000000000000000000000
    " ^ 11111111111111111111111111111111
    Expect Call('s:BitXor', 0, 4294967295) == 4294967295

    "   10000000000000000000000000000000
    " ^ 11111111111111111111111111111111
    Expect Call('s:BitXor', g:MIN_INT32, 4294967295) == g:MAX_INT32

    "   10000000000000000000000000000000
    " ^ 00000000000000000000000000000000
    Expect Call('s:BitXor', g:MIN_INT32, 0) == g:MIN_INT32
  end
end

describe "s:BitLsh"
  it "left-shifts bits of a number"
    Expect Call('s:BitLsh', 1, 1) == 2
    Expect Call('s:BitLsh', 2, 3) == 16

    "   00000000001101000101000110110101 << 1
    " = 00000000011010001010001101101010
    Expect Call('s:BitLsh', 3428789, 1) == 6857578

    "   00000000001101000101000110110101 << 9
    " = 01101000101000110110101000000000
    Expect Call('s:BitLsh', 3428789, 9) == 1755539968

    "   00000000001101000101000110110101 << 10
    " = 11010001010001101101010000000000
    Expect Call('s:BitLsh', 3428789, 10) == 3511079936

    "   00000000001101000101000110110101 << 12
    " = 01000101000110110101000000000000
    Expect Call('s:BitLsh', 3428789, 12) == 1159417856

    "   00000000001101000101000110110101 << 31
    " = 10000000000000000000000000000000
    Expect Call('s:BitLsh', 3428789, 31) == g:MIN_INT32
  end

  it "handles numbers at boundaries correctly"
    Expect Call('s:BitLsh', 0, 1) == 0
    Expect Call('s:BitLsh', g:MIN_INT32, 1) == 0
    Expect Call('s:BitLsh', g:MIN_INT32, 2) == 0
    Expect Call('s:BitLsh', g:MIN_INT32, 20) == 0

    Expect Call('s:BitLsh', g:MAX_INT32, 30) == 3221225472
    Expect Call('s:BitLsh', g:MAX_INT32, 31) == g:MIN_INT32
  end
end

describe "s:BitRsh"
  it "right-shifts bits of a number"
    Expect Call('s:BitRsh', 4, 2) == 1
    Expect Call('s:BitRsh', 3, 2) == 0
    Expect Call('s:BitRsh', 3, 10) == 0

    "   01001011110101000001010011101101 >> 1
    " = 00100101111010100000101001110110
    Expect Call('s:BitRsh', 1272190189, 1) == 636095094

    "   01001011110101000001010011101101 >> 29
    " = 00000000000000000000000000000010
    Expect Call('s:BitRsh', 1272190189, 29) == 2
    Expect Call('s:BitRsh', 1272190189, 30) == 1
    Expect Call('s:BitRsh', 1272190189, 31) == 0

    "   11111111101101010100000101111110 >> 1, 2, 10
    " = 01111111110110101010000010111111
    Expect Call('s:BitRsh', 4290068862, 1) == 2145034431
    " = 00111111111011010101000001011111
    Expect Call('s:BitRsh', 4290068862, 2) == 1072517215
    " = 00000000001111111110110101010000
    Expect Call('s:BitRsh', 4290068862, 10) == 4189520

    "   10000000000000000000000001011001 >> 1
    " = 01000000000000000000000000101100
    Expect Call('s:BitRsh', 2147483737, 1) == 1073741868

    "   10000001010101101100010101111101 >> 1, 24, 30, 31
    " = 01000000101010110110001010111110
    Expect Call('s:BitRsh', 2169947517, 1) == 1084973758
    " = 00000000000000000000000010000001
    Expect Call('s:BitRsh', 2169947517, 24) == 129
    " = 00000000000000000000000000000010
    Expect Call('s:BitRsh', 2169947517, 30) == 2
    " = 00000000000000000000000000000001
    Expect Call('s:BitRsh', 2169947517, 31) == 1
  end

  it "handles numbers at boundaries correctly"
    Expect Call('s:BitRsh', 1, 1) == 0
    Expect Call('s:BitRsh', 2, 1) == 1
    Expect Call('s:BitRsh', 2, 2) == 0

    Expect Call('s:BitRsh', 4294967295, 1) == g:MAX_INT32
    Expect Call('s:BitRsh', g:MIN_INT32, 1) == 1073741824
    Expect Call('s:BitRsh', g:MIN_INT32, 30) == 2
    Expect Call('s:BitRsh', g:MIN_INT32, 31) == 1
  end
end

describe "s:XsaddInit"
  it "produces known results for some seeds"
    " A few arbitrary results that have been verified outside of random.vim.
    Expect Call('s:XsaddInit', 1) == [3100034408, 648033277, 977804920, 1565069911]
    Expect Call('s:XsaddInit', 0) == [2793364619, 1797140415, 12629935, 2249389069]
    Expect Call('s:XsaddInit', 4294967295) == [4193126771, 785977448, 124413343, 723806811]
    Expect Call('s:XsaddInit', 34567) == [3195613172, 894861898, 4196442026, 403777717]
    Expect Call('s:XsaddInit', g:MAX_INT32) == [584683342, 1522351336, 2733367506, 3480851109]
    Expect Call('s:XsaddInit', g:MIN_INT32) == [455101706, 1469081093, 2107221962, 2849351368]
  end
end

describe "s:XsaddNextInt"
  it "produces known result for given seed"
    " Check the 40 integers produced by the test_xsadd program.
    call Call('s:XsaddInit', 1234)
    let numbers = [
        \ 1823491521, 1658333335, 1467485721,   45623648,
        \ 3336175492, 2561136018,  181953608,  768231638,
        \ 3747468990,  633754442, 1317015417, 2329323117,
        \  688642499, 1053686614, 1029905208, 3711673957,
        \ 2701869769,  695757698, 3819984643, 1221024953,
        \  110368470, 2794248395, 2962485574, 3345205107,
        \  592707216, 1730979969, 2620763022,  670475981,
        \ 1891156367, 3882783688, 1913420887, 1592951790,
        \ 2760991171, 1168232321, 1650237229, 2083267498,
        \ 2743918768, 3876980974, 2059187728, 3236392632,
        \ ]
    for n in numbers
      Expect Call('s:XsaddNextInt') == n
    endfor
  end
end

describe "s:NextInt"
  it "produces random non-negative Integers within bound"
    " A little fuzz testing.
    let thirteen = magnum#Int(13)
    for i in range(50)
      let n = Call('s:NextInt', thirteen)
      Expect n.Cmp(thirteen) < 0
      Expect n.Cmp(g:magnum#ZERO) >= 0
    endfor
  end

  it "trims trailing zeros in result"
    " Given the s:NextInt algorithm, this sequence of invocations would result
    " in the digit lists [15514, 0], [15934, 0], [2309, 0], all with trailing
    " zero. These zeros must not be in the result Integers.
    call magnum#random#SetSeed(45678)
    let n = magnum#Int(16389)
    Expect Call('s:NextInt', n)._dg == [15514]
    Expect Call('s:NextInt', n)._dg == [15934]
    Expect Call('s:NextInt', n)._dg == [2309]
  end
end

describe "magnum#random#NextInt"
  it "produces random Integers between zero and bound"
    let n = magnum#Int('9999999999999999999')
    for i in range(200)
      let random = magnum#random#NextInt(n)
      Expect random.IsNegative() to_be_false
      Expect random.Cmp(n) < 0
    endfor
  end

  it "produces random Integers in range"
    let dice = [1, 2, 3, 4, 5, 6]
    for i in range(200)
      let roll = magnum#random#NextInt(g:magnum#ONE, magnum#Int(7)).Number()
      Expect index(dice, roll) >= 0
    endfor

    let start = magnum#Int(-75797721)
    let end = magnum#Int(208274829)
    for i in range(200)
      let random = magnum#random#NextInt(start, end)
      Expect random.Cmp(start) >= 0
      Expect random.Cmp(end) < 0
    endfor
  end

  it "throws exception when passed wrong argument"
    Expect expr { magnum#random#NextInt(1) } to_throw
    Expect expr { magnum#random#NextInt(g:magnum#ONE) } not to_throw
    Expect expr { magnum#random#NextInt(g:magnum#ZERO) } to_throw
    Expect expr { magnum#random#NextInt(magnum#Int(83).Neg()) } to_throw

    Expect expr { magnum#random#NextInt(g:magnum#ONE, 14) } to_throw
    Expect expr { magnum#random#NextInt(magnum#Int(1), g:magnum#ZERO) } to_throw
    Expect expr { magnum#random#NextInt(magnum#Int(-32), magnum#Int(-669)) } to_throw
    Expect expr { magnum#random#NextInt(g:magnum#ZERO, g:magnum#ONE, 1) } not to_throw
  end
end

describe "magnum#random#SetSeed"
  it "resets random number generator state"
    let n = magnum#Int(55667788)
    call magnum#random#SetSeed(9999999)
    Expect magnum#random#NextInt(n).Number() == 33130869
    Expect magnum#random#NextInt(n).Number() != 33130869
    call magnum#random#SetSeed(9999999)
    Expect magnum#random#NextInt(n).Number() == 33130869
  end

  it "uses only the least significant 32 bits"
    let n = magnum#Int('759345739763495276934529')
    let seed = 3428789

    call magnum#random#SetSeed(seed)
    let result = magnum#random#NextInt(n)
    Expect result.String() == '77008242343885692463857'
    if has('num64')
      call magnum#random#SetSeed(seed + 0x128000000000)
      Expect magnum#random#NextInt(n).Eq(result) to_be_true
    endif
  end

  it "throws exception when passed wrong argument"
    Expect expr { magnum#random#SetSeed('nil') } to_throw
    Expect expr { magnum#random#SetSeed(g:magnum#ONE) } to_throw
  end
end
