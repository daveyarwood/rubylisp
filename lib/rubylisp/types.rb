require 'hamster/core_ext'
require 'hamster/hash'

# Monkey-patch Ruby symbols to act more like Clojure keywords
class Symbol
  def call(target)
    if [Hash, Hamster::Hash].member? target.class
      target[self]
    else
      target.instance_variable_get "@#{self.to_s}".to_sym
    end
  end
end

module RubyLisp
  class Value
    attr_accessor :value, :quoted

    def initialize(value)
      @value = value
    end

    def quote
      @quoted = true
      self
    end

    def unquote
      @quoted = false
      self
    end
  end

  class Boolean < Value; end
  class Float < Value; end
  class Int < Value; end
  class Keyword < Value; end
  class String < Value; end

  class ParseError < StandardError; end
  class RuntimeError < StandardError; end

  class HashMap < Value
    def initialize(seq)
      if seq.size.odd?
        raise RubyLisp::ParseError,
          "A RubyLisp::HashMap must contain an even number of forms."
      else
        @value = Hamster::Hash[seq.each_slice(2).to_a]
      end
    end
  end

  class List < Value
    def initialize(values)
      @value = values.to_list
    end

    def quote
      @value.each(&:quote)
      @quoted = true
      self
    end

    def unquote
      @value.each(&:unquote)
      @quoted = false
      self
    end
  end

  class Nil < Value
    def initialize
      @value = nil
    end
  end

  class Symbol < Value
    def to_s
      @value
    end

    def resolve(env)
      # rbl: (.+ 1 2)
      # ruby: 1.+(2)
      instance_method = /^\.(.*)/.match(@value).to_a[1]
      if instance_method
        return lambda {|obj, *args| obj.send instance_method, *args}
      end

      # rbl: (File::open "/tmp/foo")
      # ruby: File::open("/tmp/foo")  OR  File.open("/tmp/foo")
      #
      # rbl: Foo::Bar::BAZ
      # ruby: Foo::Bar::BAZ
      if /^\w+(::\w+)+$/ =~ @value
        first_segment, *segments = @value.split('::')
        first_segment = Object.const_get first_segment
        return segments.reduce(first_segment) do |result, segment|
          if result.class == Proc
            # a method can only be in the final position
            raise RubyLisp::RuntimeError, "Invalid value: #{@value}"
          elsif /^[A-Z]/ =~ segment
            # get module/class constant
            result.const_get segment
          else
            # if module/class method doesn't exist, trigger a NoMethodError
            result.send segment unless result.respond_to? segment
            # call module/class method
            lambda {|*args| result.send segment, *args }
          end
        end
      end

      env.get @value
    end
  end

  class Vector < Value
    def initialize(values)
      @value = Hamster::Vector.new(values)
    end
  end

end

