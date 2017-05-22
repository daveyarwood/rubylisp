require 'spec_helper'

RSpec.describe 'atoms' do
  with_rubylisp_env do
    expect_outputs \
      '#<Function: inc3>', '(defn inc3 [a] (+ 3 a))',
      /#<Concurrent::Atom.+value:2/, '(def a (atom 2))',
      'true', '(atom? a)',
      'false', '(atom? 1)',
      '2', '(deref a)',
      '2', '@a',
      '3', '(reset! a 3)',
      '3', '@a',
      '6', '(swap! a inc3)',
      '6', '@a',
      '6', '(swap! a (fn [a] a))',
      '12', '(swap! a (fn [a] (* 2 a)))',
      '120', '(swap! a (fn [a b] (* a b)) 10)',
      '123', '(swap! a + 3)',

      '#<Function: inc-it>', '(defn inc-it [a] (+ 1 a))',
      /#<Concurrent::Atom.+value:7/, '(def atm (atom 7))',
      '#<Function: f>', '(defn f [] (swap! atm inc-it))',
      '8', '(f)',
      '9', '(f)'
  end
end

