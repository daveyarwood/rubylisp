require 'spec_helper'

RSpec.describe 'fn' do
  with_rubylisp_env do
    expect_outputs \
      '7', '((fn [a b] (+ b a)) 3 4)',
      '4', '((fn [] 4))',
      '12', '(((fn [a] (fn [b] (+ a b))) 5) 7)',
      '#<Function: gen-plus5>', '(defn gen-plus5 [] (fn plus5 [b] (+ 5 b)))',
      '#<Function: plus5>', '(def plus5 (gen-plus5))',
      '12', '(plus5 7)',
      '#<Function: gen-plusX>', '(defn gen-plusX [x] (fn plusX [b] (+ x b)))',
      '#<Function: plusX>', '(def plus7 (gen-plusX 7))',
      '15', '(plus7 8)'
  end
end

RSpec.describe 'recursive fns' do
  with_rubylisp_env do
    expect_outputs \
      '#<Function: fib>', '(defn fib [n] (cond (= n 0) 1 (= n 1) 1 :else (+ (fib (- n 1)) (fib (- n 2)))))',
      '1', '(fib 1)',
      '2', '(fib 2)',
      '5', '(fib 4)',
      '21', '(fib 7)'
      # '89', '(fib 10)' # this is slow :(

    expect_outputs \
      '#<Function: sum2>', '(defn sum2 [n acc] (if (= n 0) acc (sum2 (- n 1) (+ n acc))))',
      '55', '(sum2 10 0)',
      'nil', '(def res2 nil)',
      '5050', '(def res2 (sum2 100 0))',
      '5050', 'res2'
      # '50005000', '(def res2 (sum2 10000 0))', # this is slow :(
      # '50005000', 'res2'

    # mutually recursive fns
    expect_outputs \
      '#<Function: foo>', '(defn foo [n] (if (= n 0) 0 (bar (- n 1))))',
      '#<Function: bar>', '(defn bar [n] (if (= n 0) 0 (foo (- n 1))))',
      '0', '(foo 100)'
      # '0', '(foo 10000)' # this is slow :(
  end
end

RSpec.describe 'variadic fns' do
  with_rubylisp_env do
    expect_outputs \
      '0', '((fn [& more] (count more)))',
      '1', '((fn [& more] (count more)) 1)',
      '3', '((fn [& more] (count more)) 1 2 3)',
      'true', '((fn [& more] (nil? more)))',
      'true', '((fn [& more] (list? more)) 1 2 3)',
      '0', '((fn [a & more] (count more)) 1)',
      '2', '((fn [a & more] (count more)) 1 2 3)',
      'true', '((fn [a & more] (nil? more)) 1)'
  end
end
