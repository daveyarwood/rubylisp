require 'concurrent/atom'
require 'hamster/core_ext'
require 'hamster/hash'
require 'hamster/list'
require 'hamster/vector'
require 'rubylisp/function'
require 'rubylisp/util'

include RubyLisp::Util

# Monkey-patch Ruby symbols to act more like Clojure keywords
class Symbol
	def name
		without_colon = inspect[1..-1]
    if without_colon[0] == '"' && without_colon[-1] == '"'
      without_colon[1..-2]
    else
      without_colon
    end
	end

  def call(target)
    if [Hash, Hamster::Hash].member? target.class
      target[self]
    else
      target.instance_variable_get "@#{name}".to_sym
    end
  end
end

# Monkey-patch Hamster types to have nicer (and more Clojure-like) string
# representations
module Hamster
  class Cons
    def to_s
      "(#{join " "})"
    end
  end

  module EmptyList
    def EmptyList.to_s
      "()"
    end
  end

  class Hash
    def to_s
      "{#{to_hash.map {|k, v| "#{k} #{v}"}.join ", "}}"
    end
  end

  class Vector
    def to_s
      "[#{join " "}]"
    end
  end
end

module RubyLisp
  class Value
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def to_s
      @value.to_s
    end
  end

  class ParseError < StandardError; end
  class RuntimeError < StandardError; end

  class Symbol < Value
    def to_s
      @value
    end

    def ==(other)
      other.is_a?(Symbol) && @value == other.value
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
          if result.is_a? Proc
            # a method can only be in the final position
            raise RuntimeError, "Invalid value: #{@value}"
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

  module Util
    module_function

    def hash_map(values)
      if values.size.odd?
        raise ParseError, "A hash-map must contain an even number of forms."
      else
        Hamster::Hash[values.each_slice(2).to_a]
      end
    end

    def map?(x)
      x.is_a? Hamster::Hash
    end

    def list(values)
      values.to_list
    end

    def list?(x)
      x.is_a? Hamster::List
    end

    def vec(values)
      Hamster::Vector.new(values)
    end

    def vector(*values)
      Hamster::Vector.new(values)
    end

    def vector?(x)
      x.is_a? Hamster::Vector
    end

    def sequential?(x)
      list?(x) || vector?(x)
    end
  end
end

