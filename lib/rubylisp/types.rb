def simple_type(type_name)
  new_class = Class.new(Object) do
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  RubyLisp.const_set type_name, new_class
end

simple_type "Int"
simple_type "List"
simple_type "Symbol"

