" Internal function tests

" We need to force sourcing of the autoload script here, in order to be able
" to extract the <SID> for vspec#hint below.
runtime autoload/magnum.vim

function! SID() abort
  redir => l:scriptnames
  silent scriptnames
  redir END
  for line in split(l:scriptnames, '\n')
    let [l:sid, l:path] = matchlist(line, '^\s*\(\d\+\):\s*\(.*\)$')[1:2]
    if l:path =~# '\<autoload[/\\]magnum\.vim$'
      return '<SNR>' . l:sid . '_'
    endif
  endfor
endfunction
call vspec#hint({'sid': 'SID()'})

function! ToBeZero(actual) abort
  return a:actual._dg == [] && a:actual._neg == 0
endfunction
call vspec#customize_matcher('to_be_zero', {'match': function('ToBeZero')})

function! ToBeEqual(actual, expected) abort
  return a:actual.Eq(a:expected)
endfunction
call vspec#customize_matcher('to_be_equal', {'match': function('ToBeEqual')})

function! ToHaveDigits(actual, expected) abort
  return a:actual._dg == a:expected
endfunction
call vspec#customize_matcher('to_have_digits', {'match': function('ToHaveDigits')})

let g:BASE = 16384
let g:BITS = 14

describe "s:NewInt"
  it "passes basic test"
    Expect Call('s:NewInt', [1, 2, 3], 0) to_have_digits [1, 2, 3]
    Expect Call('s:NewInt', [1, 2, 3], 0).IsPositive() to_be_true
    Expect Call('s:NewInt', [4, 5, 6], 1) to_have_digits [4, 5, 6]
    Expect Call('s:NewInt', [4, 5, 6], 1).IsNegative() to_be_true
    Expect Call('s:NewInt', [], 0) to_be_zero
    Expect Call('s:NewInt', [], 1) to_be_zero
  end
end

describe "s:TrimZeros"
  it "passes basic test"
    let x = Call('s:NewInt', [0, 1, 2], 0)
    let x1 = Call('s:NewInt', [0, 1, 2, 0], 0)
    let x2 = Call('s:NewInt', [0, 1, 2, 0, 0, 0, 0], 0)
    Expect Call('s:TrimZeros', deepcopy(x)) to_be_equal x
    Expect Call('s:TrimZeros', deepcopy(x1)) to_be_equal x
    Expect Call('s:TrimZeros', deepcopy(x2)) to_be_equal x
    let y = Call('s:NewInt', [1], 1)
    let y1 = Call('s:NewInt', [1, 0], 1)
    let y2 = Call('s:NewInt', [1, 0, 0, 0, 0, 0], 1)
    Expect Call('s:TrimZeros', deepcopy(y)) to_be_equal y
    Expect Call('s:TrimZeros', deepcopy(y1)) to_be_equal y
    Expect Call('s:TrimZeros', deepcopy(y2)) to_be_equal y
  end

  it "normalises zero representations"
    let z1 = Call('s:NewInt', [], 0)
    let z2 = Call('s:NewInt', [0], 0)
    let z3 = Call('s:NewInt', [0, 0, 0, 0], 0)
    let z4 = Call('s:NewInt', [], 1)
    let z5 = Call('s:NewInt', [0], 1)
    let z6 = Call('s:NewInt', [0, 0, 0], 1)
    Expect Call('s:TrimZeros', z1) to_be_zero
    Expect Call('s:TrimZeros', z2) to_be_zero
    Expect Call('s:TrimZeros', z3) to_be_zero
    Expect Call('s:TrimZeros', z4) to_be_zero
    Expect Call('s:TrimZeros', z5) to_be_zero
    Expect Call('s:TrimZeros', z6) to_be_zero
  end
end

describe "s:Add"
  it "passes basic test"
    " s:Add adds only the magnitudes, the sign here should be ignored.
    let x = magnum#Int(-3498)
    let y = magnum#Int(34980473)
    Expect Call('s:Add', x, x) to_be_equal magnum#Int(6996)
    Expect Call('s:Add', x, g:magnum#ZERO) to_be_equal x.Abs()
    Expect Call('s:Add', g:magnum#ZERO, x) to_be_equal x.Abs()
    Expect Call('s:Add', x, g:magnum#ONE) to_be_equal magnum#Int(3499)
    Expect Call('s:Add', g:magnum#ONE, x) to_be_equal magnum#Int(3499)
    Expect Call('s:Add', y, y) to_be_equal magnum#Int(69960946)
    Expect Call('s:Add', y, g:magnum#ZERO) to_be_equal y
    Expect Call('s:Add', g:magnum#ZERO, y) to_be_equal y
    Expect Call('s:Add', y, g:magnum#ONE) to_be_equal magnum#Int(34980474)
    Expect Call('s:Add', g:magnum#ONE, y) to_be_equal magnum#Int(34980474)
  end

  it "gives expected magnitude when adding 1 to one less than a power of BASE"
    let z = magnum#Int(g:BASE).Pow(7).Sub(g:magnum#ONE)
    let z1 = Call('s:Add', z, g:magnum#ONE)
    Expect len(z._dg) == 7
    Expect z._dg[-1] == g:BASE - 1
    Expect z._dg[-2] == g:BASE - 1
    Expect len(z1._dg) == 8
    Expect z1._dg[-1] == 1
    Expect z1._dg[-2] == 0
  end
end

describe "s:Sub"
  it "passes basic test"
    let x = magnum#Int(221501)
    let y = magnum#Int(98821)
    Expect Call('s:Sub', x, x) to_be_zero
    Expect Call('s:Sub', x.Neg(), x) to_be_zero
    Expect Call('s:Sub', x, g:magnum#ZERO) to_be_equal x
    Expect Call('s:Sub', x, g:magnum#ONE) to_be_equal magnum#Int(221500)
    Expect Call('s:Sub', x, y) to_be_equal magnum#Int(122680)
  end

  it "gives expected magnitude when subtracting 1 from a power of BASE"
    let z = magnum#Int(g:BASE).Pow(8)
    let z_1 = Call('s:Sub', z, g:magnum#ONE)
    Expect len(z_1._dg) == 8
    for digit in z_1._dg
      Expect digit == g:BASE - 1
    endfor
  end
end

describe "s:MulBasic"
  it "passes basic test"
    let a = magnum#Int(156)
    let _a = magnum#Int(-156)
    let b = magnum#Int(8922)
    let c = magnum#Int('-62454944506699772647398931630228022435853885725474360945435233414173126')
    let d = magnum#Int('580059462576425892309643338613444')
    Expect Call('s:MulBasic', a, b) to_be_equal magnum#Int(1391832)
    Expect Call('s:MulBasic', b, a) to_be_equal magnum#Int(1391832)
    Expect Call('s:MulBasic', _a, b) to_be_equal magnum#Int(1391832)
    Expect Call('s:MulBasic', b, _a) to_be_equal magnum#Int(1391832)
    Expect Call('s:MulBasic', a, g:magnum#ZERO) to_be_zero
    Expect Call('s:MulBasic', g:magnum#ZERO, a) to_be_zero
    Expect Call('s:MulBasic', _a, g:magnum#ZERO) to_be_zero
    Expect Call('s:MulBasic', g:magnum#ZERO, _a) to_be_zero
    Expect Call('s:MulBasic', a, g:magnum#ONE) to_be_equal a
    Expect Call('s:MulBasic', g:magnum#ONE, a) to_be_equal a
    Expect Call('s:MulBasic', _a, g:magnum#ONE) to_be_equal a
    Expect Call('s:MulBasic', g:magnum#ONE, _a) to_be_equal a
    Expect Call('s:MulBasic', c, d) to_be_equal magnum#Int('36227581545796772633796213935250872220616174000039803148925885532618538222950457009963666571058607105944')
    Expect Call('s:MulBasic', d, c) to_be_equal magnum#Int('36227581545796772633796213935250872220616174000039803148925885532618538222950457009963666571058607105944')
  end
end

describe "s:MulComba"
  it "passes basic test"
    let a = magnum#Int(535)
    let _a = magnum#Int(-535)
    let b = magnum#Int(89)
    let c = magnum#Int('-13368189056559969226585905007501')
    let d = magnum#Int('9433689310786302509229904643009917635298675241244453670214410044960892060917915601763')
    Expect Call('s:MulComba', a, b) to_be_equal magnum#Int(47615)
    Expect Call('s:MulComba', b, a) to_be_equal magnum#Int(47615)
    Expect Call('s:MulComba', _a, b) to_be_equal magnum#Int(47615)
    Expect Call('s:MulComba', b, _a) to_be_equal magnum#Int(47615)
    Expect Call('s:MulComba', a, g:magnum#ZERO) to_be_zero
    Expect Call('s:MulComba', g:magnum#ZERO, a) to_be_zero
    Expect Call('s:MulComba', _a, g:magnum#ZERO) to_be_zero
    Expect Call('s:MulComba', g:magnum#ZERO, _a) to_be_zero
    Expect Call('s:MulComba', a, g:magnum#ONE) to_be_equal a
    Expect Call('s:MulComba', g:magnum#ONE, a) to_be_equal a
    Expect Call('s:MulComba', _a, g:magnum#ONE) to_be_equal a
    Expect Call('s:MulComba', g:magnum#ONE, _a) to_be_equal a
    Expect Call('s:MulComba', c, d) to_be_equal magnum#Int('126111342207440207665805275310502447482539621941460455347851392034642182255905161487112642164984314035034235443824263')
    Expect Call('s:MulComba', d, c) to_be_equal magnum#Int('126111342207440207665805275310502447482539621941460455347851392034642182255905161487112642164984314035034235443824263')
  end

  it "does not overflow Vim number"
    " This depends on the fact that BASE is 2^14, and therefore the limit for
    " Comba is eight digits. Verify that the result produced by s:MulComba is
    " the same as with s:MulBasic.
    " Max value for the smaller operand is BASE^COMBA_MAX_DIGITS - 1, that is:
    let x = magnum#Int('5192296858534827628530496329220095')
    let y = magnum#Int('85070591730234615865843651857942052863')
    Expect Call('s:MulComba', x, x) to_be_equal Call('s:MulBasic', x, x)
    Expect Call('s:MulComba', x, y) to_be_equal Call('s:MulBasic', x, y)

    " TODO Add test for "+num64" after adapting COMBA_MAX_DIGITS.
    if !has('num64')
      Expect Call('s:MulComba', y, y) not to_be_equal Call('s:MulBasic', y, y)
    endif
  end
end

describe "s:LshDigits"
  it "passes basic test"
    let x = Call('s:NewInt', [1, 2, 3], 0)
    Expect Call('s:LshDigits', deepcopy(x), 0) to_be_equal x
    Expect Call('s:LshDigits', deepcopy(x), 1) to_have_digits [0, 1, 2, 3]
    Expect Call('s:LshDigits', deepcopy(x), 4) to_have_digits [0, 0, 0, 0, 1, 2, 3]
    let y = magnum#Int(g:BASE)
    Expect Call('s:LshDigits', deepcopy(y), 7) to_have_digits repeat([0], 8) + [1]
  end

  it "leaves zero alone"
    Expect Call('s:LshDigits', g:magnum#ZERO, 0) to_be_zero
    Expect Call('s:LshDigits', g:magnum#ZERO, 12) to_be_zero
  end

  it "doesn't change sign"
    let x = magnum#Int(-53999922)
    Expect Call('s:LshDigits', deepcopy(x), 0).IsNegative() to_be_true
    Expect Call('s:LshDigits', deepcopy(x), 0) to_be_equal x
    Expect Call('s:LshDigits', deepcopy(x), 1).IsNegative() to_be_true
    Expect Call('s:LshDigits', deepcopy(x), 1) to_be_equal x.Mul(magnum#Int(g:BASE))
  end
end

describe "s:RshDigits"
  it "passes basic test"
    let x = Call('s:NewInt', [11, 22, 33, 44], 0)
    Expect Call('s:RshDigits', deepcopy(x), 0) to_be_equal x
    Expect Call('s:RshDigits', deepcopy(x), 1) to_have_digits [22, 33, 44]
    Expect Call('s:RshDigits', deepcopy(x), 3) to_have_digits [44]
    Expect Call('s:RshDigits', deepcopy(x), 4) to_be_zero
    Expect Call('s:RshDigits', deepcopy(x), 78) to_be_zero
  end

  it "leaves zero alone"
    Expect Call('s:RshDigits', g:magnum#ZERO, 0) to_be_zero
    Expect Call('s:RshDigits', g:magnum#ZERO, 9) to_be_zero
  end

  it "handles sign properly"
    let x = magnum#Int(-923822)
    Expect Call('s:RshDigits', deepcopy(x), 0).IsNegative() to_be_true
    Expect Call('s:RshDigits', deepcopy(x), 0) to_be_equal x
    Expect Call('s:RshDigits', deepcopy(x), 1).IsNegative() to_be_true
    Expect Call('s:RshDigits', deepcopy(x), 1) to_be_equal x.Div(magnum#Int(g:BASE))
    Expect Call('s:RshDigits', deepcopy(x), 3).IsNegative() to_be_false
    Expect Call('s:RshDigits', deepcopy(x), 3) to_be_zero
  end
end

describe "s:Lsh"
  it "passes basic test"
    let x = magnum#Int(26)  " 11010
    Expect Call('s:Lsh', deepcopy(x), 0) to_be_equal x
    Expect Call('s:Lsh', deepcopy(x), 1) to_be_equal magnum#Int('110100', 2)
    Expect Call('s:Lsh', deepcopy(x), 3) to_be_equal magnum#Int('11010000', 2)
    Expect Call('s:Lsh', deepcopy(x), 27) to_be_equal magnum#Int('11010000000000000000000000000000', 2)
    Expect Call('s:Lsh', deepcopy(x), 28) to_be_equal magnum#Int('110100000000000000000000000000000', 2)
  end

  it "leaves zero alone"
    Expect Call('s:Lsh', g:magnum#ZERO, 0) to_be_zero
    Expect Call('s:Lsh', g:magnum#ZERO, 9) to_be_zero
    Expect Call('s:Lsh', g:magnum#ZERO, 25) to_be_zero
  end

  it "doesn't change sign"
    let x = magnum#Int(-53999)
    Expect Call('s:Lsh', deepcopy(x), 0).IsNegative() to_be_true
    Expect Call('s:Lsh', deepcopy(x), 0) to_be_equal x
    Expect Call('s:Lsh', deepcopy(x), 1).IsNegative() to_be_true
    Expect Call('s:Lsh', deepcopy(x), 1) to_be_equal magnum#Int(-107998)
  end
end

describe "s:Rsh"
  it "passes basic test"
    let x = magnum#Int(344762101)  " 10100_10001100_10100110_11110101
    Expect Call('s:Rsh', deepcopy(x), 0) to_be_equal x
    Expect Call('s:Rsh', deepcopy(x), 1) to_be_equal magnum#Int('1010010001100101001101111010', 2)
    Expect Call('s:Rsh', deepcopy(x), 2) to_be_equal magnum#Int('101001000110010100110111101', 2)
    Expect Call('s:Rsh', deepcopy(x), 23) to_be_equal magnum#Int('101001', 2)
    Expect Call('s:Rsh', deepcopy(x), 24) to_be_equal magnum#Int('10100', 2)
    Expect Call('s:Rsh', deepcopy(x), 28) to_be_equal g:magnum#ONE
    Expect Call('s:Rsh', deepcopy(x), 29) to_be_zero
    Expect Call('s:Rsh', deepcopy(x), 55) to_be_zero
  end

  it "leaves zero alone"
    Expect Call('s:Rsh', g:magnum#ZERO, 0) to_be_zero
    Expect Call('s:Rsh', g:magnum#ZERO, 6) to_be_zero
    Expect Call('s:Rsh', g:magnum#ZERO, 310) to_be_zero
  end

  it "doesn't change sign"
    let x = magnum#Int(-1410208)
    Expect Call('s:Rsh', deepcopy(x), 0).IsNegative() to_be_true
    Expect Call('s:Rsh', deepcopy(x), 0) to_be_equal x
    Expect Call('s:Rsh', deepcopy(x), 1).IsNegative() to_be_true
    Expect Call('s:Rsh', deepcopy(x), 1) to_be_equal magnum#Int(-705104)
  end
end

describe "s:MulDigit"
  it "passes basic test"
    let n_a = 13
    let a = magnum#Int(n_a)
    Expect Call('s:MulDigit', a, 0) to_be_zero
    Expect Call('s:MulDigit', a, 1) to_be_equal a
    Expect Call('s:MulDigit', a, 100) to_be_equal magnum#Int(n_a * 100)
    Expect Call('s:MulDigit', a, g:BASE-1) to_be_equal magnum#Int(n_a * (g:BASE-1))
    let n_b = 1380002
    let b = magnum#Int(n_b)
    Expect Call('s:MulDigit', b, 0) to_be_zero
    Expect Call('s:MulDigit', b, 1) to_be_equal b
    Expect Call('s:MulDigit', b, 2) to_be_equal magnum#Int(n_b * 2)
    Expect Call('s:MulDigit', b, 55) to_be_equal magnum#Int(n_b * 55)
    Expect Call('s:MulDigit', b, g:BASE-1) to_be_equal b.Mul(magnum#Int(g:BASE-1))
  end

  it "ignores sign"
    let x = magnum#Int(-88784)
    Expect Call('s:MulDigit', x, 10) to_be_equal magnum#Int(887840)
    Expect Call('s:MulDigit', x, 1) to_be_equal x.Abs()
    Expect Call('s:MulDigit', x, 0) to_be_zero
  end
end

describe "s:DivRemDigit"
  it "passes basic test"
    let a = magnum#Int(156)
    let b = magnum#Int('928736829571108572300387731')
    Expect Call('s:DivRemDigit', a, 17)[0] to_be_equal magnum#Int(9)
    Expect Call('s:DivRemDigit', a, 17)[1] == 3
    Expect Call('s:DivRemDigit', b, 189)[0] to_be_equal magnum#Int('4913951479212214668256019')
    Expect Call('s:DivRemDigit', b, 189)[1] == 140
    Expect Call('s:DivRemDigit', g:magnum#ZERO, 3)[0] to_be_zero
    Expect Call('s:DivRemDigit', g:magnum#ZERO, 3)[1] == 0
  end

  it "ignores sign of dividend"
    let x = magnum#Int(-84048)
    Expect Call('s:DivRemDigit', x, 10)[0] to_be_equal magnum#Int(8404)
    Expect Call('s:DivRemDigit', x, 10)[1] == 8
    Expect Call('s:DivRemDigit', x, 1)[0] to_be_equal magnum#Int(84048)
    Expect Call('s:DivRemDigit', x, 1)[1] == 0
  end
end

describe "s:SqrBasic"
  it "passes basic test"
    let x1 = magnum#Int(15)
    let x2 = magnum#Int(16)
    let x3 = magnum#Int('87351091839183475')
    Expect Call('s:SqrBasic', g:magnum#ZERO) to_be_zero
    Expect Call('s:SqrBasic', g:magnum#ONE) to_be_equal g:magnum#ONE
    Expect Call('s:SqrBasic', x1) to_be_equal magnum#Int(225)
    Expect Call('s:SqrBasic', x2) to_be_equal magnum#Int(256)
    Expect Call('s:SqrBasic', x3) to_be_equal magnum#Int('7630213245497465885071354713075625')
    for n in range(512) + range(-1784792999, -1784792744)
      let x = magnum#Int(n)
      Expect Call('s:SqrBasic', x) to_be_equal x.Mul(x)
    endfor
  end
end

describe "s:SqrComba"
  it "passes basic test"
    let x = magnum#Int(71)
    let y = magnum#Int('793858729283181747')
    Expect Call('s:SqrComba', g:magnum#ZERO) to_be_zero
    Expect Call('s:SqrComba', g:magnum#ONE) to_be_equal g:magnum#ONE
    Expect Call('s:SqrComba', x) to_be_equal magnum#Int(5041)
    Expect Call('s:SqrComba', y) to_be_equal magnum#Int('630211682059108044579031027833972009')
  end
end

describe "s:Sqr"
  it "passes basic test"
    let x1 = magnum#Int(15)
    let x2 = magnum#Int(16)
    let x3 = magnum#Int('87351091839183475')
    Expect Call('s:Sqr', g:magnum#ZERO) to_be_zero
    Expect Call('s:Sqr', g:magnum#ONE) to_be_equal g:magnum#ONE
    Expect Call('s:Sqr', x1) to_be_equal magnum#Int(225)
    Expect Call('s:Sqr', x2) to_be_equal magnum#Int(256)
    Expect Call('s:Sqr', x3) to_be_equal magnum#Int('7630213245497465885071354713075625')
    for n in range(512) + range(-1784792999, -1784792744)
      let x = magnum#Int(n)
      Expect Call('s:Sqr', x) to_be_equal x.Mul(x)
    endfor
  end
end

describe "s:NumberToInt"
  it "passes basic test"
    let x = 829
    let y = -9283652
    let z1 = 0x7fffffff
    let z2 = -0x80000000
    Expect Call('s:NumberToInt', 0) to_be_equal g:magnum#ZERO
    Expect Call('s:NumberToInt', 1) to_be_equal g:magnum#ONE
    Expect Call('s:NumberToInt', -1) to_be_equal g:magnum#ONE.Neg()
    Expect Call('s:NumberToInt', x) to_be_equal magnum#Int(string(x))
    Expect Call('s:NumberToInt', y) to_be_equal magnum#Int(string(y))
    Expect Call('s:NumberToInt', z1) to_be_equal magnum#Int(string(z1))
    Expect Call('s:NumberToInt', z2) to_be_equal magnum#Int(string(z2))
  end
end

describe "s:ParseInt"
  it "passes basic test"
    let x1 = '974562040'
    let x16 = '-d92afe909bb8c821'
    Expect Call('s:ParseInt', x1, 10) to_be_equal magnum#Int(974562040)
    Expect Call('s:ParseInt', x16, 16) to_be_equal magnum#Int('-15648599752293533729')
  end
end
