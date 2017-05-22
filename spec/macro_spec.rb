require 'spec_helper'

RSpec.describe 'macros' do
  expect_outputs \
    '#<Macro: one>', '(defmacro one [] 1)',
    '1', '(one)',
    '#<Macro: two>', '(defmacro two [] 2)',
    '2', '(two)',
    '#<Macro: unless>', '(defmacro unless [pred a b] `(if ~pred ~b ~a))',
    '7', '(unless false 7 8)',
    '8', '(unless true 7 8)',
    '8', '(unless true (do (println "this shouldn\'t print") 7) 8)',
    '#<Macro: unless2>', '(defmacro unless2 [pred a b] `(if (not ~pred) ~a ~b))',
    '7', '(unless2 false 7 8)',
    '8', '(unless2 true 7 8)',
    '#<Macro: identity>', '(defmacro identity [x] x)',
    '123', '(let [a 123] (identity a))'
end

RSpec.describe 'macroexpand' do
  expect_outputs \
    '#<Macro: unless2>', '(defmacro unless2 [pred a b] `(if (not ~pred) ~a ~b))',
    '(if (not 2) 3 4)', "(macroexpand '(unless2 2 3 4))"
end
