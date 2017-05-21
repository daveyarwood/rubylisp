require 'spec_helper'

RSpec.describe 'def' do
  with_rubylisp_env do
    expect_outputs \
      '3', '(def x 3)',
      '3', 'x',
      '4', '(def x 4)',
      '4', 'x',
      '8', '(def y (+ 1 7))',
      '8', 'y',
      '111', '(def mynum 111)',
      '222', '(def MYNUM 222)',
      '111', 'mynum',
      '222', 'MYNUM'

    expect_error 'Unable to resolve symbol: abc', '(abc 1 2 3)'
    expect_output '123', '(def w 123)'
    expect_error 'Unable to resolve symbol: abc', '(def w (abc))'
    expect_output '123', 'w'
  end
end

RSpec.describe 'let' do
  with_rubylisp_env do
    expect_outputs \
      '4', '(def x 4)',
      '9', '(let [z 9] z)',
      '9', '(let [x 9] x)',
      '4', 'x',
      '6', '(let [z (+ 2 3)] (+ 1 z))',
      '12', '(let [p (+ 2 3) q (+ 2 p)] (+ p q))',
      '7', '(def y (let [z 7] z))',
      '7', 'y',
      '4', '(def a 4)',
      '9', '(let [q 9] q)',
      '4', '(let [q 9] a)',
      '4', '(let [z 2] (let [q 9] a))',
      '5', '(let [x 4] (def a 5))',
      '5', 'a',
      '[3 4 5 [6 7] 8]', '(let [a 5 b 6] [3 4 a [b 7] 8])'
  end
end
