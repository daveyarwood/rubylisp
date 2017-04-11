require 'rubylisp/parser'

module RubyLisp
  class Environment
    attr_accessor :namespace, :vars, :outer

    def initialize(outer: nil, namespace: nil)
      @vars = {'*ns*' => (outer or self)}
      @outer = outer
      @namespace = namespace or
                   (outer.namespace if outer) or
                   "__ns_#{rand 10000}"
    end

    def set key, val
      @vars[key] = val
    end

    def find key
      if @vars.member? key
        self
      elsif @outer
        @outer.find key
      else
        nil
      end
    end

    def get key
      env = find key
      if env
        env.vars[key]
      else
        raise RubyLisp::RuntimeError, "Unable to resolve symbol: #{key}"
      end
    end

    # Copies all vars from `other_env` to this one.
    def refer other_env
      @vars = @vars.merge other_env.vars do |key, oldval, newval|
        if key == '*ns*'
          oldval
        else
          puts "WARNING: #{namespace}/#{key} being replaced by " +
               "#{other_env.namespace}/#{key}"
          newval
        end
      end
    end

    # TODO: some notion of "required namespaces" whose vars can be accessed when
    # qualified with the namespace name

    def load_rbl_file path
      root = File.expand_path '../..', File.dirname(__FILE__)
      input = File.read "#{root}/#{path}"

      namespace = RubyLisp::Environment.new
      RubyLisp::Parser.parse input, namespace
      namespace
    end

    def stdlib
      namespace = load_rbl_file 'rubylisp/core.rbl'
      refer namespace
      self
    end

    def repl
      namespace = load_rbl_file 'rubylisp/repl.rbl'
      refer namespace
      self
    end
  end
end
