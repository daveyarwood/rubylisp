require 'rubylisp/types'

module RubyLisp
  module Printer
    module_function

    def pr_str(x)
      case x
      when Array, Hamster::Vector
        "[#{x.map {|item| pr_str(item)}.join(' ')}]"
      when Hash
        "{#{x.map {|k, v| "#{pr_str(k)} #{pr_str(v)}"}.join ", "}}"
      when Hamster::Hash
        pr_str x.to_hash
      when Hamster::List
        "(#{x.map {|item| pr_str(item)}.join(' ')})"
      when RubyLisp::Keyword
        ":#{x.value}"
      when RubyLisp::List
        "(#{x.value.map {|item| pr_str(item)}.join(' ')})"
      when RubyLisp::Symbol, RubyLisp::Int, RubyLisp::Float
        x.value
      else
        x.inspect
      end
    end
  end
end
