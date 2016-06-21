" Benchmark tests
"
" These tests do not test proper functioning, but instead they run certain
" operations a large number of times and record the time used. For each test,
" the measurement result is output on a separate line following the test
" result (which is always 'ok'). For example:
"
"       ok 5 - Integer.Add adds 10000 large Integers
"       # (1.039)

function! StartTime() abort
  let g:time = eval(reltimestr(reltime()))
endfunction

function! StopAndReportTime() abort
  let g:time = eval(reltimestr(reltime())) - g:time
  echo '# ' . printf('(%.3f)', g:time)
endfunction

describe "magnum#Int"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "instantiates 10000 Integers from number"
    for i in range(5000)
      let _ = magnum#Int(123)
      let _ = magnum#Int(456748320)
    endfor
  end

  it "instantiates 1000 Integers from string"
    for i in range(1000)
      let _ = magnum#Int('9012345')
    endfor
  end
end

describe "Integer.Cmp"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "compares 10000 equal Integers"
    let x1 = magnum#Int(745198321)
    let x2 = magnum#Int('745198321')
    for i in range(10000)
      let _ = x1.Cmp(x2)
    endfor
  end

  it "compares 10000 Integers with different sign"
    let x = magnum#Int(-682736441)
    let y = magnum#Int(78273)
    for i in range(10000)
      let _ = x.Cmp(y)
    endfor
  end

  it "compares 10000 Integers with different magnitude"
    let x = magnum#Int('-8948270028482849')
    let y = magnum#Int('-78273644929700287384382024793983')
    for i in range(10000)
      let _ = x.Cmp(y)
    endfor
  end

  it "compares 10000 very close Integers"
    let x = magnum#Int('78273644929700287384382024793984')
    let y = magnum#Int('78273644929700287384382024793983')
    for i in range(10000)
      let _ = x.Cmp(y)
    endfor
  end
end

describe "Integer.Add"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "adds 10000 small Integers"
    let x = magnum#Int(8900)
    let y = magnum#Int(12)
    let z = magnum#Int(-5001063)
    for i in range(5000)
      let _ = x.Add(y)
      let _ = y.Add(z)
    endfor
  end

  it "adds 5000 larger Integers"
    let x = magnum#Int(252358)
    let y = magnum#Int('92735434918112834290134')
    for i in range(5000)
      let _ = x.Add(y)
    endfor
  end
end

describe "Integer.Mul"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "multiplies 10000 small Integers"
    let x = magnum#Int(82)
    let y = magnum#Int(9891)
    for i in range(10000)
      let _ = x.Mul(y)
    endfor
  end

  it "multiplies 5000 larger Integers"
    let x = magnum#Int(829847)
    let y = magnum#Int('98283705028461189489401330')
    for i in range(5000)
      let _ = x.Mul(y)
    endfor
  end
end

describe "Integer.DivRem"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "divides 10000 small Integers"
    let x = magnum#Int(823712)
    let y = magnum#Int(891)
    for i in range(10000)
      let _ = x.DivRem(y)
    endfor
  end

  it "divides 1000 larger Integers"
    let x = magnum#Int('23871236517524605229334')
    let y = magnum#Int(93100483)
    for i in range(1000)
      let _ = x.DivRem(y)
    endfor
  end
end

describe "Integer.Pow"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "raises to 1000 small powers"
    let x = magnum#Int(82)
    for i in range(1000)
      let _ = x.Pow(6)
    endfor
  end

  it "raises to 100 large powers"
    let x = magnum#Int(829847)
    for i in range(100)
      let _ = x.Pow(31)
    endfor
  end
end

describe "Integer.String"
  before
    call StartTime()
  end

  after
    call StopAndReportTime()
  end

  it "converts 2000 small Integers to decimal string"
    let x = magnum#Int('2984')
    for i in range(2000)
      let _ = x.String()
    endfor
  end

  it "converts 1000 larger Integers to decimal string"
    let x = magnum#Int('9082328741718')
    for i in range(1000)
      let _ = x.String()
    endfor
  end
end
