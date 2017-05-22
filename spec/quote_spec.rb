require 'spec_helper'

RSpec.describe 'quote' do
  with_rubylisp_env do
    expect_outputs \
      '7', '(quote 7)',
      '7', "'7",
      '(1 2 3)', '(quote (1 2 3))',
      '(1 2 3)', "'(1 2 3)",
      '(1 2 (3 4))', '(quote (1 2 (3 4)))'
  end
end

RSpec.describe 'quasiquote' do
  with_rubylisp_env do
    expect_outputs \
      '7', '(quasiquote 7)',
      '7', '`7',
      '(1 2 3)', '(quasiquote (1 2 3))',
      '(1 2 3)', '`(1 2 3)',
      '(1 2 (3 4))', '(quasiquote (1 2 (3 4)))',
      '(nil)', '(quasiquote (nil))'
  end
end

RSpec.describe 'unquote' do
  with_rubylisp_env do
    expect_outputs \
      '7', '(quasiquote (unquote 7))',
      '7', '`~7',
      '8', '(def a 8)',
      'a', '(quasiquote a)',
      'a', '`a',
      '8', '(quasiquote (unquote a))',
      '8', '`~a',
      '(1 a 3)', '`(1 a 3)',
      '(1 8 3)', '`(1 ~a 3)',
      '(1 "b" "d")', '(def b (quote (1 "b" "d")))',
      '(1 b 3)', '`(1 b 3)',
      '(1 (1 "b" "d") 3)', '`(1 ~b 3)',
      '[1 a 3]', '`[1 a 3]',
      '[1 8 3]', '`[1 ~a 3]'
  end
end

RSpec.describe 'splice-unquote' do
  with_rubylisp_env do
    expect_outputs \
      '(1 "b" "d")', '(def c \'(1 "b" "d"))',
      '(1 c 3)', '`(1 c 3)',
      '(1 1 "b" "d" 3)', '`(1 ~@c 3)',
      '(1 1 "b" "d" 3)', '(quasiquote (1 (splice-unquote c) 3))',
      '[1 1 "b" "d" 3]', '`[1 ~@c 3]'
  end
end

RSpec.describe 'symbol equality' do
  with_rubylisp_env do
    expect_outputs \
      'true', "(= 'abc 'abc)",
      'true', '(= (quote abc) (quote abc))',
      'false', "(= 'abc 'abcd)",
      'false', '(= \'abc "abc")',
      'false', '(= "abc" \'abc)',
      'true', '(= "abc" (str \'abc))',
      'false', "(= 'abc nil)",
      'false', "(= nil 'abc)"
  end
end

RSpec.describe 'quoting quine' do
  quine = '((fn [q] (quasiquote ((unquote q) (quote (unquote q))))) (quote (fn [q] (quasiquote ((unquote q) (quote (unquote q)))))))'

  with_rubylisp_env do
    expect_output quine, quine
  end
end
