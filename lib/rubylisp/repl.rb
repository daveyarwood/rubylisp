require 'readline'

module RubyLisp
  module REPL
    module_function

    def read input
      input
    end

    def eval_ast input
      input
    end

    def print input
      input
    end

    def rep input
      print(eval_ast(read(input)))
    end

    def start
      while buf = Readline.readline('user> ', true)
        p buf
      end
    end
  end
end
