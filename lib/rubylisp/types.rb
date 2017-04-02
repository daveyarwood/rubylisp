def really_simple_type(type_name)
  RubyLisp.const_set type_name, Class.new(Object)
end

def simple_type(type_name)
  new_class = Class.new(Object) do
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  RubyLisp.const_set type_name, new_class
end

def error_type(type_name)
  RubyLisp.const_set type_name, Class.new(StandardError)
end

really_simple_type "Nil"
simple_type "Boolean"
simple_type "Int"
simple_type "Keyword"
simple_type "List"
simple_type "String"
simple_type "Symbol"
simple_type "Vector"
error_type "ParseError"

