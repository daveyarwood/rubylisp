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

    def read_seq(type, end_token, seq=[])
      case peek
      when nil
        raise RubyLisp::ParseError, "Unexpected EOF while parsing #{type}."
      when end_token
        next_token
        type.new(seq)
      else
        seq << read_form
        read_seq(type, end_token, seq)
      end
    end

    def read_list
      read_seq RubyLisp::List, ')'
    end

    def read_vector
      read_seq RubyLisp::Vector, ']'
    end

    def read_atom
      token = next_token
      case token
      when /^\-?\d+$/
        RubyLisp::Int.new(token.to_i)
      when /^".*"$/
        # it's safe to use eval here because the tokenizer ensures that
        # the token is an escaped string representation
        RubyLisp::String.new(eval(token))
      when 'nil'
        RubyLisp::Nil.new
      when 'true'
        RubyLisp::Boolean.new(true)
      when 'false'
        RubyLisp::Boolean.new(false)
      else
        RubyLisp::Symbol.new(token)
      end
    end

    def read_form
      case peek
      when '('
        next_token
        read_list
      when '['
        next_token
        read_vector
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
