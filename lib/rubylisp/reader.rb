require 'rubylisp/types'

module RubyLisp
  class Reader
    # from kanaka/mal
    TOKEN_REGEX = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/

    attr_accessor :tokens, :position

    def peek
      @tokens[@position]
    end

    def next_token
      token = peek
      @position += 1
      token
    end

    def read_list(list=[])
      case peek
      when nil
        raise "Unexpected EOF while parsing list."
      when ')'
        next_token
        RubyLisp::List.new(list)
      else
        list << read_form
        read_list(list)
      end
    end

    def read_atom
      token = next_token
      case token
      when /^\-?\d+$/
        RubyLisp::Int.new(token.to_i)
      else
        RubyLisp::Symbol.new(token)
      end
    end

    def read_form
      case peek
      when '('
        next_token
        read_list
      else
        read_atom
      end
    end

    def tokenize str
      @tokens = str.scan(TOKEN_REGEX)
                   .flatten
                   .reject {|token| token.empty?}
      @position = 0
    end

    def Reader.read_str str
      reader = Reader.new
      reader.tokenize(str)
      reader.read_form
    end
  end
end
