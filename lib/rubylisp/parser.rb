require 'rubylisp/printer'
require 'rubylisp/reader'
require 'rubylisp/environment'
require 'rubylisp/evaluator'

module RubyLisp
  module Parser
    module_function

    def read input
      Reader.read_str input
    end

    def eval_ast input, env
      Evaluator.eval_ast input, env
    end

    def print input
      Printer.pr_str input
    end

    def parse input, env = Environment.new.stdlib
      ast = read input
      result = eval_ast ast, env
      print result
    end
  end
end
