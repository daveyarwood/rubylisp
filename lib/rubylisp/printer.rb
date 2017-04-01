module RubyLisp
  module Printer
    module_function

    def pr_str(x)
      case x
      when RubyLisp::Int
        x.value.to_s
      when RubyLisp::List
        "(#{x.value.map {|item| pr_str(item)}.join(' ')})"
      when RubyLisp::Symbol
        x.value
      else
        raise "Unable to print #{x}."
      end
    end
  end
end
