require 'spec_helper'

RSpec.describe 'if' do
  with_rubylisp_env do
    expect_outputs \
      '"no"', '(if (> (count (list 1 2 3)) 3) "yes" "no")',
      '"yes"', '(if (>= (count (list 1 2 3)) 3) "yes" "no")',
      '7', '(if true 7 8)',
      '8', '(if false 7 8)',
      '8', '(if true (+ 1 7) (+ 1 8))',
      '9', '(if false (+ 1 7) (+ 1 8))',
      '9', '(if false (do (println "this shouldn\'t print") (+ 1 7)) (+ 1 8))',
      '8', '(if nil 7 8)',
      '7', '(if 0 7 8)',
      '7', '(if "" 7 8)',
      '7', '(if (list) 7 8)',
      '7', '(if (list 1 2 3) 7 8)',
      '7', '(if [] 7 8)',
      'nil', '(if false (+ 1 7))',
      '8', '(if true (+ 1 7))'
  end
end

RSpec.describe 'do' do
  with_rubylisp_env do
    expect_outputs \
      "\"prn output1\"\nnil", '(do (prn "prn output1"))',
      "\"prn output2\"\n7", '(do (prn "prn output2") 7)',
      "\"prn output1\"\n\"prn output2\"\n3", '(do (prn "prn output1") (prn "prn output2") (+ 1 2))',
      '14', '(do (def a 6) 7 (+ a 8))',
      '6', 'a',
      '2', '(do (do 1 2))',
      # testing special form case-sensitivity
      '#<Function: DO>', '(defn DO [a] 7)',
      '7', '(DO 3)'
  end
end

RSpec.describe 'not' do
  with_rubylisp_env do
    expect_outputs \
      'true', '(not false)',
      'false', '(not true)',
      'false', '(not "a")',
      'false', '(not 0)'
  end
end
