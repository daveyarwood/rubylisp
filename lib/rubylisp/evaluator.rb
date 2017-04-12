require 'rubylisp/environment'
require 'rubylisp/printer'
require 'rubylisp/types'

module RubyLisp
  module Evaluator
    module_function

    def assert_number_of_args sexp, num_args
      fn, *args = sexp.value
      fn_name = fn.value
      unless args.count == num_args
        raise RubyLisp::RuntimeError,
              "Wrong number of arguments passed to `#{fn_name}`; " +
              "got #{args.count}, expected #{num_args}."
      end
    end

    def assert_at_least_n_args sexp, num_args
      fn, *args = sexp.value
      fn_name = fn.value
      unless args.count >= num_args
        raise RubyLisp::RuntimeError,
              "Wrong number of arguments passed to `#{fn_name}`; " +
              "got #{args.count}, expected at least #{num_args}."
      end
    end

    def assert_arg_type sexp, arg_number, arg_type
      fn = sexp.value[0]
      fn_name = fn.value
      arg = if arg_number == 'last'
              sexp.value.last
            else
              sexp.value[arg_number]
            end

      arg_description = if arg_number == 'last'
                          'The last argument'
                        else
                          "Argument ##{arg_number}"
                        end

      arg_types = if arg_type.class == Array
                    arg_type
                  else
                    [arg_type]
                  end

      expected = case arg_types.count
                 when 1
                   arg_types.first
                 when 2
                   arg_types.join(' or ')
                 else
                   last_arg_type = arg_types.pop
                   arg_types.join(', ') + " or #{last_arg_type}"
                 end

      if arg_types.none? {|type| arg.is_a? type}
        raise RubyLisp::RuntimeError,
              "#{arg_description} to `#{fn_name}` must be a " +
              "#{expected}; got a #{arg.class}."
      end
    end

    def eval_ast input, env
      # loop forever until a value is returned;
      # this is for tail call optimization
      while true
        case input
        when Array # of ASTs to be evaluated, e.g. multiple expressions in a file
          # discard nils that can be produced by the reader, e.g. when a comment
          # is read
          input = input.compact

          # if input is empty (e.g. only comments), there is nothing to evaluate
          return nil if input.empty?

          # discard the return value of all but the last form
          input[0..-2].each {|form| eval_ast(form, env)}
          # recur; evaluate and return the value of the last form
          input = input.last
        when RubyLisp::HashMap
          return input.value.map {|k, v| [eval_ast(k, env), eval_ast(v, env)]}
        when RubyLisp::List
          if input.value.empty?
            return input.value
          elsif input.value[0].value == 'apply'
            # FIXME: undefined method :call for RubyLisp::Function I think after
            # implementing TCO, we need to define apply as a macro. So this will
            # be broken until macros are implemented. :(
            raise "This is broken. TODO: reimplement `apply` as a macro."

            # evaluate the last argument
            coll = eval_ast(input.value[-1], env) || Hamster::Vector[]
            # assert that it's enumerable
            sexp = RubyLisp::List.new(input.value.fill(coll, -1, 1))
            assert_arg_type sexp, 'last', Enumerable

            # drop `apply` and pull the last form's contents into the sexp as
            # multiple arguments
            all_but_last_arg = sexp.value[1..-2].map {|arg| eval_ast arg, env}
            fn, *args = all_but_last_arg + coll.to_list
            sexp = RubyLisp::List.new([RubyLisp::Symbol.new("apply"), fn])
            assert_arg_type sexp, 1, [RubyLisp::Function, Proc]
            return fn.call(*args)
          elsif input.value[0].value == 'def'
            assert_arg_type input, 1, RubyLisp::Symbol
            key, val = input.value[1..-1]
            return env.set key.value, eval_ast(val, env)
          elsif input.value[0].value == 'do'
            body = input.value[1..-1]
            # discard the return values of all but the last form
            body[0..-2].each {|form| eval_ast(form, env)}
            # recur; evaluate and return the last form
            input = body.last
          elsif input.value[0].value == 'fn'
            if input.value[1].class == RubyLisp::Symbol
              fn_name = input.value[1].value
              bindings, *body = input.value[2..-1]
            else
              fn_name = "__fn_#{rand 10000}"
              bindings, *body = input.value[1..-1]
            end

            unless bindings.class == RubyLisp::Vector
              raise RubyLisp::RuntimeError,
                    "The bindings of `fn` must be a RubyLisp::Vector."
            end

            bindings.value.each do |binding|
              unless binding.class == RubyLisp::Symbol
                raise RubyLisp::RuntimeError,
                      "Each binding for `fn` must be a symbol."
              end
            end

            # bindings is now an array of strings (symbol names)
            bindings = bindings.value.map(&:value)

            ampersand_indices = bindings.to_list.indices {|x| x == '&'}
            if ampersand_indices.any? {|i| i != bindings.count - 2}
              raise RubyLisp::RuntimeError,
                    "An '&' can only occur right before the last binding."
            end

            return RubyLisp::Function.new(fn_name, env, bindings, body)
          elsif input.value[0].value == 'if'
            cond, then_form, else_form = input.value[1..-1]
            unless then_form
              raise RubyLisp::RuntimeError,
                    "An `if` form must at least have a 'then' branch."
            end

            if (eval_ast cond, env)
              input = then_form
            elsif else_form
              input = else_form
            else
              return nil
            end
          elsif input.value[0].value == 'in-ns'
            assert_number_of_args input, 1
            input.value[1] = eval_ast(input.value[1], env)
            assert_arg_type input, 1, RubyLisp::Symbol
            ns_name = input.value[1].to_s
            # TODO: register ns and switch to it
            return env.namespace = ns_name
          elsif input.value[0].value == 'let'
            assert_arg_type input, 1, RubyLisp::Vector
            inner_env = RubyLisp::Environment.new(outer: env)
            bindings, *body = input.value[1..-1]
            unless bindings.value.count.even?
              raise RubyLisp::RuntimeError,
                    "The bindings vector of `let` must contain an even number " +
                    " of forms."
            end

            bindings.value.each_slice(2) do |(k, v)|
              inner_env.set k.value, eval_ast(v, inner_env)
            end

            # discard the return values of all but the last form
            body[0..-2].each {|form| eval_ast(form, inner_env)}
            # recur; evaluate and return the last form's value
            env = inner_env
            input = body.last
          elsif input.value[0].value == 'ns'
            # ns will be defined more robustly in rbl.core, but rbl.core also
            # needs the `ns` form in order to declare that it is rbl.core.
            #
            # defining it here in a minimal form where it is equivalent to in-ns,
            # except that you don't have to quote the namespace name
            assert_number_of_args input, 1
            assert_arg_type input, 1, RubyLisp::Symbol
            ns_name = input.value[1].to_s
            # TODO: register ns and switch to it
            return env.namespace = ns_name
          elsif input.value[0].value == 'quote'
            assert_number_of_args input, 1
            fn, *args = input.value
            quoted_form = args[0]

            if [RubyLisp::HashMap, RubyLisp::List, RubyLisp::Vector].member? quoted_form.class
              return quoted_form.quote.value
            else
              return quoted_form.quote
            end
          elsif input.value[0].value == 'resolve'
            assert_number_of_args input, 1
            symbol = eval_ast(input.value[1], env)
            sexp = RubyLisp::List.new(input.value.fill(symbol, 1, 1))
            assert_arg_type sexp, 1, RubyLisp::Symbol
            return symbol.resolve(env)
          else
            fn, *args = input.value.map {|value| eval_ast(value, env)}
            if fn.class == RubyLisp::Function
              # recur with input and env set to the body of the function and an
              # inner environment where the function's bindings are set to the
              # values of the arguments
              input = fn.body
              env = RubyLisp::Environment.new(outer: fn.env)
              # so the fn can call itself recursively
              env.set(fn.name, fn)

              sexp = RubyLisp::List.new([RubyLisp::Symbol.new(fn.name), *args])
              if fn.bindings.any? {|binding| binding == '&'}
                required_args = fn.bindings.count - 2
                assert_at_least_n_args sexp, required_args

                fn.bindings[0..-3].zip(args.take(required_args)).each do |k, v|
                  env.set(k, v)
                end

                rest_args = if args.count > required_args
                              args[required_args..-1].to_list
                            else
                              nil
                            end

                env.set(fn.bindings.last, rest_args)
              else
                required_args = fn.bindings.count
                assert_number_of_args sexp, required_args

                fn.bindings.zip(args).each do |k, v|
                  env.set(k, v)
                end
              end
            else
              return fn.call(*args)
            end
          end
        when RubyLisp::Symbol
          if input.quoted
            return input
          else
            return input.resolve(env)
          end
        when RubyLisp::Vector
          return input.value.map {|value| eval_ast(value, env)}
        else
          return input.value
        end
      end
    end
  end
end
