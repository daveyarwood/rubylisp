module RubyLisp
  module Printer
    module_function

    def pr_str(x)
      case x
      when RubyLisp::Boolean
        x.value ? 'true' : 'false'
      when RubyLisp::HashMap
        "{#{x.value.map {|k, v| "#{pr_str(k)} #{pr_str(v)}"}.join ", "}}"
      when RubyLisp::Int
        x.value.to_s
      when RubyLisp::Keyword
        ":#{x.value.to_s}"
      when RubyLisp::List
        "(#{x.value.map {|item| pr_str(item)}.join(' ')})"
      when RubyLisp::Nil
        'nil'
      when RubyLisp::String
        x.value.inspect
      when RubyLisp::Symbol
        x.value
      when RubyLisp::Vector
        "[#{x.value.map {|item| pr_str(item)}.join(' ')}]"
      else
        x.inspect
      end
    end
  end
end
