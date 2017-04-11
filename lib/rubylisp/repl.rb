require 'readline'
require 'rubylisp/environment'
require 'rubylisp/parser'

module RubyLisp
  module REPL
    module_function

    def start
      env = RubyLisp::Environment.new(namespace: 'user').stdlib.repl

      while buf = Readline.readline("#{env.namespace}> ", true)
        begin
          input = buf.nil? ? '' : buf.strip
          puts input.empty? ? '' : RubyLisp::Parser.parse(input, env)
        rescue => e
          # If an error happens, print it like Ruby would and continue accepting
          # REPL input.
          puts e.backtrace
                .join("\n\t")
                .sub("\n\t", ": #{e}#{e.class ? " (#{e.class})" : ''}\n\t")
        end
      end
    end
  end
end
