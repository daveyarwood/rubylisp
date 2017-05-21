require 'spec_helper'

RSpec.describe 'math' do
  with_rubylisp_env do
    expect_outputs \
      '3', '(+ 1 2)',
      '11', '(+ 5 (* 2 3))',
      '8', '(- (+ 5 (* 2 3)) 3)',
      '2', '(/ (- (+ 5 (* 2 3)) 3) 4)',
      '1010', '(/ (- (+ 515 (* 87 311)) 302) 27)',
      '-18', '(* -3 6)',
      '-994', '(/ (- (+ 515 (* -87 311)) 296) 27)',
      '()', '()'
  end
end

RSpec.describe 'math inside collections' do
  with_rubylisp_env do
    expect_outputs \
      '[1 2 3]', '[1 2 (+ 1 2)]',
      '{"a" 15}', '{"a" (+ 7 8)}',
      '{:a 15}', '{:a (+ 7 8)}'
  end
end

RSpec.describe '=' do
  with_rubylisp_env do
    expect_outputs \
      'false', '(= (list) nil)',
      'true', '(= (list) (list))',
      'true', '(= (list 1 2) (list 1 2))',
      'false', '(= (list 1) (list))',
      'false', '(= (list) (list 1))',
      'false', '(= 0 (list))',
      'false', '(= (list) 0)',
      'false', '(= (list) "")',
      'false', '(= "" (list))',
      'false', '(= 2 1)',
      'true', '(= 1 1)',
      'true', '(= 0 0)',
      'false', '(= 1 2)',
      'false', '(= 1 0)',
      'false', '(= 1 (+ 1 1))',
      'true', '(= 2 (+ 1 1))',
      'false', '(= nil 1)',
      'true', '(= nil nil)',
      'true', '(= "" "")',
      'true', '(= "abc" "abc")',
      'false', '(= "abc" "")',
      'false', '(= "" "abc")',
      'false', '(= "abc" "def")',
      'false', '(= "abc" "ABC")',
      'true', '(= :abc :abc)',
      'false', '(= :abc :def)',
      'false', '(= :abc ":abc")',
      'true', '(= [] (list))',
      'true', '(= [7 8] [7 8])',
      'true', '(= (list 1 2) [1 2])',
      'false', '(= (list 1) [])',
      'false', '(= [] [1])',
      'false', '(= 0 [])',
      'false', '(= [] 0)',
      'false', '(= [] "")',
      'false', '(= "" [])',
      # tests fail: nested vector/list equality doesn't work in Hamster library
      'true', '(= [(list)] (list []))',
      'true', '(= [1 2 (list 3 4 [5 6])] (list 1 2 [3 4 (list 5 6)]))'
  end
end

RSpec.describe '<, <=, >, >=' do
  with_rubylisp_env do
    expect_outputs \
      'true', '(> 2 1)',
      'false', '(> 1 1)',
      'false', '(> 1 2)',
      'true', '(>= 2 1)',
      'true', '(>= 1 1)',
      'false', '(>= 1 2)',
      'false', '(< 2 1)',
      'false', '(< 1 1)',
      'true', '(< 1 2)',
      'false', '(<= 2 1)',
      'true', '(<= 1 1)',
      'true', '(<= 1 2)'
  end
end

