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
        if type == RubyLisp::HashMap
          if seq.size.odd?
            raise RubyLisp::ParseError, "A RubyLisp::HashMap must contain an even number of forms."
          else
            next_token
            hashmap = seq.each_slice(2).to_a.to_h
            type.new(hashmap)
          end
        else
          next_token
          type.new(seq)
        end
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

    def read_hashmap
      read_seq RubyLisp::HashMap, '}'
    end

    def read_atom
      token = next_token
      case token
      when nil
        nil
      when /^\-?\d+$/
        RubyLisp::Int.new(token.to_i)
      when /^".*"$/
        # it's safe to use eval here because the tokenizer ensures that
        # the token is an escaped string representation
        RubyLisp::String.new(eval(token))
      # it's a little weird that an unfinished string (e.g. "abc) gets
        # tokenized as "", but at least the behavior is consistent ¯\_(ツ)_/¯
      when ""
        raise RubyLisp::ParseError, "Unexpected EOF while parsing RubyLisp::String."
      when /^:/
        RubyLisp::Keyword.new(token[1..-1].to_sym)
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

    def read_quoted_form
      form = read_form
      RubyLisp::List.new([RubyLisp::Symbol.new("quote"), form])
    end

    def read_quasiquoted_form
      form = read_form
      RubyLisp::List.new([RubyLisp::Symbol.new("quasiquote"), form])
    end

    def read_unquoted_form
      form = read_form
      RubyLisp::List.new([RubyLisp::Symbol.new("unquote"), form])
    end

    def read_splice_unquoted_form
      form = read_form
      RubyLisp::List.new([RubyLisp::Symbol.new("splice-unquote"), form])
    end

    def read_form
      case peek
      when /^;/
        # ignore comments
        next_token
        read_form
      when '('
        next_token
        read_list
      when '['
        next_token
        read_vector
      when '{'
        next_token
        read_hashmap
      when "'"
        next_token
        read_quoted_form
      when "`"
        next_token
        read_quasiquoted_form
      when "~"
        next_token
        read_unquoted_form
      when "~@"
        next_token
        read_splice_unquoted_form
      else
        read_atom
      end
    end

    def tokenize str
      @tokens = str.scan(TOKEN_REGEX).flatten[0...-1]
      @position = 0
    end

    def Reader.read_str str
      reader = Reader.new
      reader.tokenize(str)
      reader.read_form
    end
  end
end
