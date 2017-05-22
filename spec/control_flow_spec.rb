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

RSpec.describe 'or' do
  with_rubylisp_env do
    expect_outputs \
      'nil', '(or)',
      '1', '(or 1)',
      '1', '(or 1 2 3 4)',
      '1', '(or 1 2 3 4 (println "this shouldn\'t print"))',
      '2', '(or false 2)',
      '3', '(or false nil 3)',
      '4', '(or false nil false false nil 4)',
      '3', '(or false nil 3 false nil 4)',
      '4', '(or (or false 4))',
      '"yes"', '(let [x (or nil "yes")] x)'
  end
end

RSpec.describe 'cond' do
  with_rubylisp_env do
    expect_outputs \
      'nil', '(cond)',
      '7', '(cond true 7)',
      '7', '(cond true 7 true 8)',
      '8', '(cond false 7 true 8)',
      '9', '(cond false 7 false 8 :else 9)',
      '8', '(cond false 7 (= 2 2) 8 :else 9)',
      'nil', '(cond false 7 false 8 false 9)'
  end
end

RSpec.describe '->' do
  with_rubylisp_env do
    expect_outputs \
      '7', '(-> 7)',
      '7', '(-> (list 7 8 9) first)',
      '7', '(-> (list 7 8 9) (first))',
      '14', '(-> (list 7 8 9) first (+ 7))',
      '16', '(-> (list 7 8 9) rest (rest) first (+ 7))'
  end
end

RSpec.describe '->>' do
  with_rubylisp_env do
    expect_outputs \
      '"L"', '(->> "L")',
      '"MAL"', '(->> "L" (str "A") (str "M"))',
      '(1 3 4)', '(->> [4] (concat [3]) (concat [2]) rest (concat [1]))'
  end
end
