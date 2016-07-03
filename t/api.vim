" API tests

function! ToBeZero(actual) abort
  return a:actual._dg == [] && a:actual._neg == 0
endfunction
call vspec#customize_matcher('to_be_zero', {'match': function('ToBeZero')})

function! ToBeEqual(actual, expected) abort
  return a:actual.Eq(a:expected)
endfunction
call vspec#customize_matcher('to_be_equal', {'match': function('ToBeEqual')})

describe "magnum#Int"
  it "passes basic test"
    Expect type(magnum#Int(1)) == type({})
  end

  it "accepts number or string argument"
    Expect expr { magnum#Int(14) } not to_throw
    Expect expr { magnum#Int('14') } not to_throw
    Expect expr { magnum#Int('14', 16) } not to_throw
    Expect expr { magnum#Int({}) } to_throw
    Expect expr { magnum#Int(3.14) } to_throw
  end
end

describe "Integer.IsZero"
  it "passes basic test"
    Expect g:magnum#ZERO.IsZero() to_be_true
    Expect magnum#Int('0').IsZero() to_be_true
    Expect magnum#Int('-0', 31).IsZero() to_be_true
    Expect g:magnum#ZERO.Neg().IsZero() to_be_true
    Expect g:magnum#ONE.IsZero() to_be_false
    Expect magnum#Int(-1).IsZero() to_be_false
  end
end

describe "Integer.IsPositive"
  it "passes basic test"
    Expect magnum#Int(-1).IsPositive() to_be_false
    Expect g:magnum#ZERO.IsPositive() to_be_false
    Expect g:magnum#ONE.IsPositive() to_be_true
    Expect magnum#Int(-3).Abs().IsPositive() to_be_true
    Expect magnum#Int('-32777', 8).IsPositive() to_be_false
  end
end

describe "Integer.IsNegative"
  it "passes basic test"
    Expect magnum#Int(-1).IsNegative() to_be_true
    Expect g:magnum#ZERO.IsNegative() to_be_false
    Expect g:magnum#ONE.IsNegative() to_be_false
    Expect magnum#Int(-5).Abs().IsNegative() to_be_false
    Expect magnum#Int('-4523', 6).IsNegative() to_be_true
  end
end

describe "Integer.IsEven"
  it "passes basic test"
    Expect g:magnum#ZERO.IsEven() to_be_true
    Expect g:magnum#ONE.IsEven() to_be_false
    Expect magnum#Int(-2).IsEven() to_be_true
    Expect magnum#Int('13982410752394872').IsEven() to_be_true
    Expect magnum#Int('13982410752394873').IsEven() to_be_false
    Expect magnum#Int('-13982410752394872').IsEven() to_be_true
    Expect magnum#Int('-13982410752394873').IsEven() to_be_false
  end
end

describe "Integer.IsOdd"
  it "passes basic test"
    Expect g:magnum#ZERO.IsOdd() to_be_false
    Expect g:magnum#ONE.IsOdd() to_be_true
    Expect magnum#Int(-2).IsOdd() to_be_false
    Expect magnum#Int('13982410752394872').IsOdd() to_be_false
    Expect magnum#Int('13982410752394873').IsOdd() to_be_true
    Expect magnum#Int('-13982410752394872').IsOdd() to_be_false
    Expect magnum#Int('-13982410752394873').IsOdd() to_be_true
  end
end

describe "Integer.Add"
  it "passes basic test"
    let x = magnum#Int(79)
    let y = magnum#Int(-1293019844)
    let z = magnum#Int('91837460138764108320384728453651383777385787853874')
    Expect x.Add(g:magnum#ZERO) to_be_equal x
    Expect g:magnum#ZERO.Add(x) to_be_equal x
    Expect x.Add(g:magnum#ONE) to_be_equal magnum#Int(80)
    Expect g:magnum#ONE.Add(x) to_be_equal magnum#Int(80)
    Expect x.Add(y) to_be_equal magnum#Int(-1293019765)
    Expect y.Add(x) to_be_equal magnum#Int(-1293019765)
    Expect y.Add(g:magnum#ZERO) to_be_equal y
    Expect g:magnum#ZERO.Add(y) to_be_equal y
    Expect y.Add(g:magnum#ONE) to_be_equal magnum#Int(-1293019843)
    Expect g:magnum#ONE.Add(y) to_be_equal magnum#Int(-1293019843)
    Expect y.Add(z) to_be_equal magnum#Int('91837460138764108320384728453651383777384494834030')
    Expect z.Add(y) to_be_equal magnum#Int('91837460138764108320384728453651383777384494834030')
  end

  it "handles signs correctly"
    let n5 = magnum#Int(5)
    let n_5 = magnum#Int(-5)
    let n3 = magnum#Int(3)
    let n_3 = magnum#Int(-3)
    Expect n5.Add(n5).Number()   == 10
    Expect n5.Add(n_5).Number()  == 0
    Expect n5.Add(n3).Number()   == 8
    Expect n5.Add(n_3).Number()  == 2
    Expect n_5.Add(n5).Number()  == 0
    Expect n_5.Add(n_5).Number() == -10
    Expect n_5.Add(n3).Number()  == -2
    Expect n_5.Add(n_3).Number() == -8
    Expect n3.Add(n5).Number()   == 8
    Expect n3.Add(n_5).Number()  == -2
    Expect n3.Add(n3).Number()   == 6
    Expect n3.Add(n_3).Number()  == 0
    Expect n_3.Add(n5).Number()  == 2
    Expect n_3.Add(n_5).Number() == -8
    Expect n_3.Add(n3).Number()  == 0
    Expect n_3.Add(n_3).Number() == -6
  end

  it "throws exception when passed wrong argument"
    Expect expr { magnum#Int(10).Add('invalid') } to_throw
    Expect expr { magnum#Int(10).Add(0.1) } to_throw
  end
end

describe "Integer.Sub"
  it "passes basic test"
    let x = magnum#Int(-281)
    let y = magnum#Int(281997439)
    let z = magnum#Int('-35143713724162260567352411903813817205211034209908482')
    Expect x.Sub(g:magnum#ZERO) to_be_equal x
    Expect g:magnum#ZERO.Sub(x) to_be_equal x.Neg()
    Expect x.Sub(g:magnum#ONE) to_be_equal magnum#Int(-282)
    Expect g:magnum#ONE.Sub(x) to_be_equal magnum#Int(282)
    Expect x.Sub(y) to_be_equal magnum#Int(-281997720)
    Expect y.Sub(x) to_be_equal magnum#Int(281997720)
    Expect y.Sub(g:magnum#ZERO) to_be_equal y
    Expect g:magnum#ZERO.Sub(y) to_be_equal y.Neg()
    Expect y.Sub(g:magnum#ONE) to_be_equal magnum#Int(281997438)
    Expect g:magnum#ONE.Sub(y) to_be_equal magnum#Int(-281997438)
    Expect y.Sub(z) to_be_equal magnum#Int('35143713724162260567352411903813817205211034491905921')
    Expect z.Sub(y) to_be_equal magnum#Int('-35143713724162260567352411903813817205211034491905921')
  end

  it "handles signs correctly"
    let n5 = magnum#Int(5)
    let n_5 = magnum#Int(-5)
    let n3 = magnum#Int(3)
    let n_3 = magnum#Int(-3)
    Expect n5.Sub(n5).Number()   == 0
    Expect n5.Sub(n_5).Number()  == 10
    Expect n5.Sub(n3).Number()   == 2
    Expect n5.Sub(n_3).Number()  == 8
    Expect n_5.Sub(n5).Number()  == -10
    Expect n_5.Sub(n_5).Number() == 0
    Expect n_5.Sub(n3).Number()  == -8
    Expect n_5.Sub(n_3).Number() == -2
    Expect n3.Sub(n5).Number()   == -2
    Expect n3.Sub(n_5).Number()  == 8
    Expect n3.Sub(n3).Number()   == 0
    Expect n3.Sub(n_3).Number()  == 6
    Expect n_3.Sub(n5).Number()  == -8
    Expect n_3.Sub(n_5).Number() == 2
    Expect n_3.Sub(n3).Number()  == -6
    Expect n_3.Sub(n_3).Number() == 0
  end

  it "throws exception when passed wrong argument"
    Expect expr { magnum#Int(10).Sub([]) } to_throw
    Expect expr { magnum#Int(10).Sub('invalid') } to_throw
  end
end

describe "Integer.Mul"
  it "passes basic test"
    let a = magnum#Int(39)
    let b = magnum#Int(84101)
    let c = magnum#Int('-928351982457238682938450')
    Expect a.Mul(b).Number() == 3279939
    Expect b.Mul(a).Number() == 3279939
    Expect a.Mul(c) to_be_equal magnum#Int('-36205727315832308634599550')
    Expect b.Mul(c) to_be_equal magnum#Int('-78075330076636230473806583450')
    Expect c.Mul(c) to_be_equal magnum#Int('861837403332285199315026496191088407126488402500')
  end

  it "handles signs correctly"
    let n2 = magnum#Int(2)
    let n_2 = magnum#Int(-2)
    let n4 = magnum#Int(4)
    let n_4 = magnum#Int(-4)
    Expect n2.Mul(n2).Number() == 4
    Expect n2.Mul(n_2).Number() == -4
    Expect n2.Mul(g:magnum#ZERO) to_be_zero
    Expect n_2.Mul(n2).Number() == -4
    Expect n_2.Mul(n_2).Number() == 4
    Expect n_2.Mul(g:magnum#ZERO) to_be_zero
  end

  it "throws exception when passed wrong argument"
    Expect expr { magnum#Int(8).Mul(99) } to_throw
    Expect expr { magnum#Int(8).Mul([]) } to_throw
  end
end

describe "Integer.DivRem"
  it "passes basic test"
    let x = magnum#Int(7839248)
    let y = magnum#Int(8349)
    Expect x.DivRem(y)[0] to_be_equal magnum#Int(938)
    Expect x.DivRem(y)[1] to_be_equal magnum#Int(7886)
    Expect x.DivRem(g:magnum#ONE)[0] to_be_equal x
    Expect x.DivRem(g:magnum#ONE)[1] to_be_zero
    Expect x.DivRem(x)[0] to_be_equal g:magnum#ONE
    Expect x.DivRem(x)[1] to_be_zero
  end

  it "throws exception on division by zero"
    let x = magnum#Int(5)
    Expect expr { g:magnum#ZERO.DivRem(g:magnum#ZERO) } to_throw
    Expect expr { x.DivRem(g:magnum#ZERO) } to_throw
    Expect expr { x.Neg().DivRem(g:magnum#ZERO) } to_throw
  end

  it "handles sign correctly"
    let x = magnum#Int('8521829477511988382263')
    let y = magnum#Int(83871171)
    Expect x.DivRem(y)[0] to_be_equal magnum#Int('101606182147045')
    Expect x.DivRem(y)[1] to_be_equal magnum#Int(30042568)
    Expect x.DivRem(y.Neg())[0] to_be_equal magnum#Int('-101606182147045')
    Expect x.DivRem(y.Neg())[1] to_be_equal magnum#Int(30042568)
    Expect x.Neg().DivRem(y)[0] to_be_equal magnum#Int('-101606182147045')
    Expect x.Neg().DivRem(y)[1] to_be_equal magnum#Int(-30042568)
    Expect x.Neg().DivRem(y.Neg())[0] to_be_equal magnum#Int('101606182147045')
    Expect x.Neg().DivRem(y.Neg())[1] to_be_equal magnum#Int(-30042568)
    " Implementation detail: we know that sign handling for single-digit
    " divisors is implemented separately, so we want to test that too.
    let x = magnum#Int(13)
    let y = magnum#Int(4)  " less than BASE
    Expect x.DivRem(y)[0] to_be_equal magnum#Int(3)
    Expect x.DivRem(y)[1] to_be_equal magnum#Int(1)
    Expect x.DivRem(y.Neg())[0] to_be_equal magnum#Int(-3)
    Expect x.DivRem(y.Neg())[1] to_be_equal magnum#Int(1)
    Expect x.Neg().DivRem(y)[0] to_be_equal magnum#Int(-3)
    Expect x.Neg().DivRem(y)[1] to_be_equal magnum#Int(-1)
    Expect x.Neg().DivRem(y.Neg())[0] to_be_equal magnum#Int(3)
    Expect x.Neg().DivRem(y.Neg())[1] to_be_equal magnum#Int(-1)
  end

  it "gives correct results when quotient becomes zero"
    let x = magnum#Int(1111)
    let y = magnum#Int(1112)
    Expect x.DivRem(y)[0] to_be_zero
    Expect x.DivRem(y)[1] to_be_equal x
    Expect x.DivRem(y.Neg())[0] to_be_zero
    Expect x.DivRem(y.Neg())[1] to_be_equal x
    Expect x.Neg().DivRem(y)[0] to_be_zero
    Expect x.Neg().DivRem(y)[1] to_be_equal x.Neg()
    Expect x.Neg().DivRem(y.Neg())[0] to_be_zero
    Expect x.Neg().DivRem(y.Neg())[1] to_be_equal x.Neg()
  end
end

describe "Integer.Pow"
  it "passes basic test"
    Expect g:magnum#ZERO.Pow(42) to_be_zero
    Expect g:magnum#ONE.Pow(42) to_be_equal g:magnum#ONE
    Expect magnum#Int(2).Pow(64) to_be_equal magnum#Int('18446744073709551616')
    Expect magnum#Int(2).Pow(723) to_be_equal magnum#Int('44125218104815898389829825659447310364864904872680898823178155169729591099393726561029280015550468702670279148410687446533176513529349858556664892007608532912981188929417439383947376132698492620683708741856789536964608')
    let x = magnum#Int(8476)
    let xm = g:magnum#ONE
    for i in range(7)
      let xm = xm.Mul(x)
    endfor
    Expect x.Pow(7) to_be_equal xm
    Expect g:magnum#ONE.Pow(0x7fffffff) to_be_equal g:magnum#ONE
  end

  it "handles sign correctly"
    let x = magnum#Int(-9)
    Expect x.Pow(0) to_be_equal g:magnum#ONE
    Expect x.Pow(1) to_be_equal x
    Expect x.Pow(2) to_be_equal magnum#Int(81)
    Expect x.Pow(3) to_be_equal magnum#Int(-729)
    let n_1 = g:magnum#ONE.Neg()
    Expect n_1.Pow(0x7ffffffe) to_be_equal g:magnum#ONE
    Expect n_1.Pow(0x7fffffff) to_be_equal g:magnum#ONE.Neg()
  end

  it "throws exception for invalid argument"
    Expect expr { magnum#Int(3).Pow(g:magnum#ONE) } to_throw
    Expect expr { magnum#Int(3).Pow({'invalid': 1}) } to_throw
    Expect expr { magnum#Int(3).Pow(-1) } to_throw
  end
end

describe "Integer.Number"
  it "passes basic test"
    Expect magnum#Int(0).Number() == 0
    Expect magnum#Int(13).Number() == 13
    Expect magnum#Int('13').Number() == 13
    Expect magnum#Int(-0x9a).Number() == -0x9a
    Expect magnum#Int('-9a', 16).Number() == -0x9a
    Expect magnum#Int(99184821).Number() == 99184821
    Expect magnum#Int(-311389840).Number() == -311389840
  end

  it "throws exception on integer overflow"
    if has('num64')
      Expect expr { magnum#Int('100000000000000000000000').Number() } to_throw
      Expect expr { magnum#Int('9230000000000000000').Number() } to_throw
      Expect expr { magnum#Int('9223372036854775809').Number() } to_throw
      Expect expr { magnum#Int('9223372036854775808').Number() } to_throw
      Expect magnum#Int('9223372036854775807').Number() == 9223372036854775807
      Expect magnum#Int('9223372036854775806').Number() == 9223372036854775806
      Expect magnum#Int('9223372036854775792').Number() == 9223372036854775792
      Expect magnum#Int('-9223372036854775792').Number() == -9223372036854775792
      Expect magnum#Int('-9223372036854775807').Number() == -9223372036854775807
      Expect magnum#Int('-9223372036854775808').Number() == -9223372036854775808
      Expect expr { magnum#Int('-9223372036854775809').Number() } to_throw
      Expect expr { magnum#Int('-9223372036854775810').Number() } to_throw
      Expect expr { magnum#Int('-9223400000000000000').Number() } to_throw
      Expect expr { magnum#Int('-999999999999999999999999999').Number() } to_throw
    else
      Expect expr { magnum#Int('10000000000').Number() } to_throw
      Expect expr { magnum#Int('2200000000').Number() } to_throw
      Expect expr { magnum#Int('2147483649').Number() } to_throw
      Expect expr { magnum#Int('2147483648').Number() } to_throw
      Expect magnum#Int('2147483647').Number() == 2147483647
      Expect magnum#Int('2147483646').Number() == 2147483646
      Expect magnum#Int('2147483639').Number() == 2147483639
      Expect magnum#Int('-2147483639').Number() == -2147483639
      Expect magnum#Int('-2147483647').Number() == -2147483647
      Expect magnum#Int('-2147483648').Number() == -2147483648
      Expect expr { magnum#Int('-2147483649').Number() } to_throw
      Expect expr { magnum#Int('-2147483650').Number() } to_throw
      Expect expr { magnum#Int('-2150000000').Number() } to_throw
      Expect expr { magnum#Int('-99999999999999').Number() } to_throw
    endif
  end
end

describe "Integer.String"
  it "passes basic test"
    Expect g:magnum#ZERO.String() ==# '0'
    Expect g:magnum#ZERO.Neg().String() ==# '0'
    let x = '7837453'
    let y = 'de53af820ec711b2'
    Expect magnum#Int(x).String() ==# x
    Expect magnum#Int(y, 16).String(16) ==# y
  end

  it "accepts base argument"
    let a = magnum#Int(81356)
    let b = magnum#Int(-81356)
    Expect expr { a.String('16') } to_throw
    Expect expr { a.String(16) } not to_throw
    Expect a.String(16) ==# '13dcc'
    Expect expr { b.String(37) } to_throw
    Expect expr { b.String(36) } not to_throw
    Expect b.String(36) ==# '-1qrw'
    let c = magnum#Int('43920284438948269')
    Expect c.String(10) ==# c.String()
  end
end

describe "magnum"
  it "passes the telephone game test"
    let whisper = '10100110111110010011100001100001110010101011101110100001'
    let secret = magnum#Int(whisper, 2)
    Expect secret.String(2) ==# whisper

    " Whisper the secret message along the chain of all bases.
    let message = whisper
    let chain = range(2, 36) + [2]
    for i in range(len(chain)-1)
      let heard = magnum#Int(message, chain[i])
      Expect heard to_be_equal secret
      let message = heard.String(chain[i+1])
    endfor
    Expect message ==# whisper
  end
end
