require 'spec_helper'

RSpec.describe 'misc list functions' do
  with_rubylisp_env do
    expect_outputs \
      '()', '(list)',
      'true', '(list? (list))',
      'true', '(empty? (list))',
      'false', '(empty? (list 1))',
      '(1 2 3)', '(list 1 2 3)',
      '3', '(count (list 1 2 3))',
      '0', '(count (list))',
      '0', '(count nil)',

      '[]', '[]',
      '[1 2 3]', '[1 2 3]',
      'false', '(list? [])',
      'false', '(list? [4 5 6])',
      'true', '(empty? [])',
      'false', '(empty? [1])',
      '3', '(count [1 2 3])',
      '0', '(count [])'
  end
end

RSpec.describe 'cons' do
  with_rubylisp_env do
    expect_outputs \
      '(1)', '(cons 1 (list))',
      '(1 2)', '(cons 1 (list 2))',
      '(1 2)', "(cons 1 '(2))",
      '(1 2 3)', '(cons 1 (list 2 3))',
      '((1) 2 3)', '(cons (list 1) (list 2 3))',
      '(2 3)', '(def a (list 2 3))',
      '(1 2 3)', '(cons 1 a)',
      '(2 3)', 'a',
      '([1] 2 3)', '(cons [1] [2 3])',
      '(1 2 3)', '(cons 1 [2 3])'
  end
end

RSpec.describe 'concat' do
  with_rubylisp_env do
    expect_outputs \
      '()', '(concat)',
      '(1 2)', '(concat (list 1 2))',
      '(1 2 3 4)', '(concat (list 1 2) (list 3 4))',
      '(1 2 3 4 5 6)', '(concat (list 1 2) (list 3 4) (list 5 6))',
      '()', '(concat (concat))',
      '(1 2)', '(def a (list 1 2))',
      '(3 4)', '(def b (list 3 4))',
      '(1 2 3 4 5 6)', '(concat a b (list 5 6))',
      '(1 2)', 'a',
      '(3 4)', 'b',
      '(1 2 3 4 5 6)', '(concat [1 2] (list 3 4) [5 6])'
  end
end
