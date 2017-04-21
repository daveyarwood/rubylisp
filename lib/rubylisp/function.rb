require 'rubylisp/types'

module RubyLisp
  class Arity
    attr_accessor :body, :required_args, :rest_args

    def initialize(ast)
      unless list? ast
        raise RuntimeError,
          "Invalid signature #{arity}; expected a list."
      end

      bindings, *body = ast

      unless vector? bindings
        raise RuntimeError,
          "Bindings must be a vector; got #{body.class}."
      end

      bindings.each do |binding|
        unless binding.class == Symbol
          raise RuntimeError,
            "Each binding must be a symbol; got #{binding.class}."
        end
      end

      # bindings is now an array of strings (symbol names)
      bindings = bindings.map(&:value)

      ampersand_indices = bindings.to_list.indices {|x| x == '&'}
      if ampersand_indices.any? {|i| i != bindings.count - 2}
        raise RuntimeError,
          "An '&' can only occur right before the last binding."
      end

      @required_args = bindings.take_while {|binding| binding != '&'}
      @rest_args = bindings.drop_while {|binding| binding != '&'}.drop(1)
      @body = body
    end
  end


  class Function < Proc
    attr_accessor :name, :env, :bindings, :body, :is_macro, :lambda

    def initialize(name, env, asts, &block)
      super()
      @name = name
      @env = env
      @arities = construct_arities(asts)
      @is_macro = false
      @lambda = block
    end

    def construct_arities(asts)
      arities_hash = asts.each_with_object({'arities' => [],
                                            'required' => 0}) do |ast, result|
        arity = Arity.new(ast)

        if arity.rest_args.empty?
          # Prevent conflicts like [x] vs. [y]
          if result['arities'].any? {|existing|
            existing.required_args.count == arity.required_args.count &&
            existing.rest_args.empty?
          }
            raise RuntimeError,
                  "Can't have multiple overloads with the same arity."
          end

          # Prevent conflicts like [& xs] vs. [x]
          if result['rest_required']
            unless arity.required_args.count <= result['rest_required']
            raise RuntimeError,
                  "Can't have a fixed arity function with more params than a " +
                  "variadic function."
            end
          end
        else
          # Prevent conflicts like [x] vs. [& xs]
          if arity.required_args.count < result['required']
            raise RuntimeError,
                  "Can't have a fixed arity function with more params than a " +
                  "variadic function."
          end

          # Prevent conflicts like [x & xs] vs. [x y & ys]
          if result['arities'].any? {|existing| !existing.rest_args.empty?}
            raise RuntimeError,
                  "Can't have more than one variadic overload."
          end

          result['rest_required'] = arity.required_args.count
        end

        result['required'] = [result['required'], arity.required_args.count].max
        result['arities'] << arity
      end

      arities_hash['arities']
    end

    def get_arity(args)
      # Assert that there are enough arguments provided for the arities we have.
      sexp = list [Symbol.new(@name), *args]
      variadic = @arities.find {|arity| !arity.rest_args.empty?}
      fixed_arities = @arities.select {|arity| arity.rest_args.empty?}
      fixed = fixed_arities.find {|arity| arity.required_args.count == args.count}

      # Return the arity most appropriate for the number of args provided.
      if fixed
        fixed
      elsif variadic
        assert_at_least_n_args sexp, variadic.required_args.count
        variadic
      else
        raise RuntimeError,
              "Wrong number of args (#{args.count}) passed to #{@name}"
      end
    end

    def gen_env(arity, args, env)
      # set out_env to the current namespace so that `def` occurring within
      # the fn's environment will define things in the namespace in which the
      # function is called
      out_env = env.out_env || env.find_namespace
      env = Environment.new(outer: @env, out_env: out_env)
      # so the fn can call itself recursively
      env.set(@name, self)

      if arity.rest_args.empty?
        # bind values to the required args
        arity.required_args.zip(args).each do |k, v|
          env.set(k, v)
        end
      else
        # bind values to the required args (the rest args are skipped here)
        arity.required_args.zip(args).each do |k, v|
          env.set(k, v)
        end

        # bind the rest argument to the remaining arguments or nil
        rest_args = if args.count > arity.required_args.count
                      args[arity.required_args.count..-1].to_list
                    else
                      nil
                    end

        env.set(arity.rest_args.first, rest_args)
      end

      env
    end
  end
end
