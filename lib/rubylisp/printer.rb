require 'rubylisp/types'

module RubyLisp
  module Printer
    module_function

    def pr_str(*xs)
      if xs.count > 1
        xs.map {|x| pr_str(x)}.join(' ')
      else
        x = xs.first
        case x
        when Array, Hamster::Vector
          "[#{x.map {|item| pr_str(item)}.join(' ')}]"
        when Hash
          "{#{x.map {|k, v| "#{pr_str(k)} #{pr_str(v)}"}.join ", "}}"
        when Hamster::Hash
          pr_str x.to_hash
        when Hamster::List
          "(#{x.map {|item| pr_str(item)}.join(' ')})"
        when RubyLisp::Function
          "#<RubyLisp::Function: #{x.name}>"
        when RubyLisp::List
          "(#{x.value.map {|item| pr_str(item)}.join(' ')})"
        when RubyLisp::Symbol, RubyLisp::String, RubyLisp::Int, RubyLisp::Float,
             RubyLisp::Boolean, RubyLisp::Keyword
          x.value
        else
          x.inspect
        end
      end
    end
  end
end
