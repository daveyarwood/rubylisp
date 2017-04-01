require 'readline'
require 'rubylisp/printer'
require 'rubylisp/reader'

module RubyLisp
  module REPL
    module_function

    def read input
      RubyLisp::Reader.read_str input
    end

    def eval_ast input
      input
    end

    def print input
      RubyLisp::Printer.pr_str input
    end

    def rep input
      print(eval_ast(read(input)))
    end

    def start
      while buf = Readline.readline('user> ', true)
        puts rep(buf)
      end
    end
  end
end
