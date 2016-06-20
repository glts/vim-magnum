" Random number generator tests

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

let g:MIN_INT = 0x80000000
let g:MAX_INT = 0x7fffffff

describe "Vim number arithmetic"
  it "passes basic sanity check"
    Expect g:MIN_INT + 1 == -g:MAX_INT
    Expect g:MIN_INT + g:MIN_INT == 0
    Expect g:MIN_INT + g:MIN_INT == 0
    Expect g:MAX_INT + g:MAX_INT == -2
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
    Expect Call('s:BitXor', 54471, -502042175) == -502029050

    "   11100000000000000000000000000000
    " ^ 00011111111111111111111111111111
    Expect Call('s:BitXor', -536870912, 536870911) == -1
  end

  it "handles numbers at boundaries correctly"
    "   01111111111111111111111111111111
    " ^ 00000000000000000000000000000000
    Expect Call('s:BitXor', g:MAX_INT, 0) == g:MAX_INT

    "   01111111111111111111111111111111
    " ^ 01111111111111111111111111111111
    Expect Call('s:BitXor', g:MAX_INT, g:MAX_INT) == 0

    "   01111111111111111111111111111111
    " ^ 11111111111111111111111111111111
    Expect Call('s:BitXor', g:MAX_INT, -1) == g:MIN_INT

    "   00000000000000000000000000000000
    " ^ 11111111111111111111111111111111
    Expect Call('s:BitXor', 0, -1) == -1

    "   10000000000000000000000000000000
    " ^ 11111111111111111111111111111111
    Expect Call('s:BitXor', g:MIN_INT, -1) == g:MAX_INT

    "   10000000000000000000000000000000
    " ^ 00000000000000000000000000000000
    Expect Call('s:BitXor', g:MIN_INT, 0) == g:MIN_INT
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
    Expect Call('s:BitLsh', 3428789, 10) == -783887360

    "   00000000001101000101000110110101 << 12
    " = 01000101000110110101000000000000
    Expect Call('s:BitLsh', 3428789, 12) == 1159417856

    "   00000000001101000101000110110101 << 31
    " = 10000000000000000000000000000000
    Expect Call('s:BitLsh', 3428789, 31) == g:MIN_INT
  end

  it "handles numbers at boundaries correctly"
    Expect Call('s:BitLsh', 0, 1) == 0
    Expect Call('s:BitLsh', g:MIN_INT, 1) == 0
    Expect Call('s:BitLsh', g:MIN_INT, 2) == 0
    Expect Call('s:BitLsh', g:MIN_INT, 20) == 0

    Expect Call('s:BitLsh', g:MAX_INT, 30) == -1073741824
    Expect Call('s:BitLsh', g:MAX_INT, 31) == g:MIN_INT
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
    Expect Call('s:BitRsh', -4898434, 1) == 2145034431
    " = 00111111111011010101000001011111
    Expect Call('s:BitRsh', -4898434, 2) == 1072517215
    " = 00000000001111111110110101010000
    Expect Call('s:BitRsh', -4898434, 10) == 4189520

    "   10000000000000000000000001011001 >> 1
    " = 01000000000000000000000000101100
    Expect Call('s:BitRsh', -2147483559, 1) == 1073741868

    "   10000001010101101100010101111101 >> 1, 24, 30, 31
    " = 01000000101010110110001010111110
    Expect Call('s:BitRsh', -2125019779, 1) == 1084973758
    " = 00000000000000000000000010000001
    Expect Call('s:BitRsh', -2125019779, 24) == 129
    " = 00000000000000000000000000000010
    Expect Call('s:BitRsh', -2125019779, 30) == 2
    " = 00000000000000000000000000000001
    Expect Call('s:BitRsh', -2125019779, 31) == 1
  end

  it "handles numbers at boundaries correctly"
    Expect Call('s:BitRsh', 1, 1) == 0
    Expect Call('s:BitRsh', 2, 1) == 1
    Expect Call('s:BitRsh', 2, 2) == 0

    Expect Call('s:BitRsh', -1, 1) == g:MAX_INT
    Expect Call('s:BitRsh', g:MIN_INT, 1) == 1073741824
    Expect Call('s:BitRsh', g:MIN_INT, 30) == 2
    Expect Call('s:BitRsh', g:MIN_INT, 31) == 1
  end
end

describe "s:XsaddInit"
  it "produces known results for some seeds"
    " A few arbitrary results that have been verified outside of random.vim.
    Expect Call('s:XsaddInit', 1) == [-1194932888, 648033277, 977804920, 1565069911]
    Expect Call('s:XsaddInit', 0) == [-1501602677, 1797140415, 12629935, -2045578227]
    Expect Call('s:XsaddInit', -1) == [-101840525, 785977448, 124413343, 723806811]
    Expect Call('s:XsaddInit', 34567) == [-1099354124, 894861898, -98525270, 403777717]
    Expect Call('s:XsaddInit', g:MAX_INT) == [584683342, 1522351336, -1561599790, -814116187]
    Expect Call('s:XsaddInit', g:MIN_INT) == [455101706, 1469081093, 2107221962, -1445615928]
  end
end

describe "s:XsaddNextInt"
  it "produces known result for given seed"
    " Check the 40 integers produced by the test_xsadd program. Some of the
    " number literals in the list below overflow but it doesn't matter.
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

describe "magnum#random#NextInt"
  it "produces random numbers in range"
    " A little fuzz testing.
    call magnum#random#SetSeed(localtime())
    let thirteen = magnum#Int(13)
    for i in range(50)
      let n = magnum#random#NextInt(thirteen)
      Expect n.Cmp(thirteen) < 0
      Expect n.Cmp(g:magnum#ZERO) >= 0
    endfor
  end

  it "trims trailing zeroes in result"
    " Given the magnum#random#NextInt algorithm, this sequence of invocations
    " would result in the digit lists [15514, 0], [15934, 0], [2309, 0], all
    " with trailing zero. These zeroes must not be in the result Integers.
    call magnum#random#SetSeed(45678)
    let n = magnum#Int(16389)
    Expect magnum#random#NextInt(n)._dg == [15514]
    Expect magnum#random#NextInt(n)._dg == [15934]
    Expect magnum#random#NextInt(n)._dg == [2309]
  end

  it "throws exception when passed wrong argument"
    Expect expr { magnum#random#NextInt({'too': 0xBAD}) } to_throw
    Expect expr { magnum#random#NextInt(1) } to_throw
    Expect expr { magnum#random#NextInt(g:magnum#ONE) } not to_throw

    Expect expr { magnum#random#NextInt(magnum#Int(83).Neg()) } to_throw
    Expect expr { magnum#random#NextInt(g:magnum#ZERO) } to_throw
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

  it "throws exception when passed wrong argument"
    Expect expr { magnum#random#SetSeed('nil') } to_throw
    Expect expr { magnum#random#SetSeed(g:magnum#ONE) } to_throw
  end
end
