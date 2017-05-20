require 'rubylisp/types'

module RubyLisp
  class Reader
    # from kanaka/mal
    TOKEN_REGEX = %r{
      # ignore whitespace and commas
      [\s,]*

      # match any of...
      (
        # the splice-unquote reader macro
        ~@|

        # special characters
        [\[\]{}()'`~^@]|

        # strings
        "(?:\\.|[^\\"])*"|

        # comments
        ;.*|

        # any sequence of non-special characters
        # e.g. symbols, numbers, keywords, booleans, etc.
        [^\s\[\]{}('"`,;)]*
      )
    }x

    attr_accessor :tokens, :position

    def peek
      @tokens[@position]
    end

    def next_token
      token = peek
      @position += 1
      token
    end

    def read_seq(type_name, constructor, end_token, seq=[])
      case peek
      when nil
        raise ParseError, "Unexpected EOF while parsing #{type_name}."
      when end_token
        next_token
        constructor.call(seq)
      else
        seq << read_form
        read_seq(type_name, constructor, end_token, seq)
      end
    end

    def read_list
      read_seq 'list', RubyLisp.method(:list), ')'
    end

    def read_vector
      read_seq 'vector', RubyLisp.method(:vec), ']'
    end

    def read_hashmap
      read_seq 'hash-map', RubyLisp.method(:hash_map), '}'
    end

    def read_atom
      token = next_token
      case token
      when nil
        nil
      when /^\-?\d+$/
        Value.new(token.to_i)
      when /^\-?\d+\.\d+$/
        Value.new(token.to_f)
      when /^".*"$/
        # it's safe to use eval here because the tokenizer ensures that
        # the token is an escaped string representation
        Value.new(eval(token))
      # it's a little weird that an unfinished string (e.g. "abc) gets
      # tokenized as "", but at least the behavior is consistent ¯\_(ツ)_/¯
      when ""
        raise ParseError, "Unexpected EOF while parsing string."
      when /^:/
        Value.new(token[1..-1].to_sym)
      when 'nil'
        Value.new(nil)
      when 'true'
        Value.new(true)
      when 'false'
        Value.new(false)
      else
        Symbol.new(token)
      end
    end

    def read_special_form(special)
      form = read_form
      unless form
        raise ParseError, "Unexpected EOF while parsing #{special} form."
      end
      list [Symbol.new(special), form]
    end

    def read_quoted_form
      read_special_form 'quote'
    end

    def read_quasiquoted_form
      read_special_form 'quasiquote'
    end

    def read_unquoted_form
      read_special_form 'unquote'
    end

    def read_splice_unquoted_form
      read_special_form 'splice-unquote'
    end

    def read_deref_form
      read_special_form 'deref'
    end

    def read_form_with_metadata
      token = peek
      case token
      when nil
        raise ParseError, "Unexpected EOF while parsing metadata."
      when '{'
        next_token
        metadata = read_hashmap
      when /^:/
        kw = read_form
        metadata = hash_map [kw, Value.new(true)]
      else
        raise ParseError, "Invalid metadata: '#{token}'"
      end

      form = read_form
      unless form
        raise ParseError, "Unexpected EOF after metadata."
      end

      list [Symbol.new("with-meta"), form, metadata]
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
      when ')'
        raise ParseError, "Unexpected ')'."
      when ']'
        raise ParseError, "Unexpected ']'."
      when '}'
        raise ParseError, "Unexpected '}'."
      when "'"
        next_token
        read_quoted_form
      when '`'
        next_token
        read_quasiquoted_form
      when '~'
        next_token
        read_unquoted_form
      when '~@'
        next_token
        read_splice_unquoted_form
      when '@'
        next_token
        read_deref_form
      when '^'
        next_token
        read_form_with_metadata
      else
        read_atom
      end
    end

    def tokenize str
      @tokens = str.strip.scan(TOKEN_REGEX).flatten[0...-1]
      @position = 0
    end

    def Reader.read_str str
      reader = Reader.new
      reader.tokenize(str)
      forms = []
      while reader.position < reader.tokens.count
        forms << reader.read_form
      end
      forms
    end
  end
end
