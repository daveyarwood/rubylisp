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
      case input
      when Array # of ASTs to be evaluated, e.g. multiple expressions in a file
        input.compact.map {|form| eval_ast(form, env)}.last
      when RubyLisp::HashMap
        input.value.map {|k, v| [eval_ast(k, env), eval_ast(v, env)]}
      when RubyLisp::List
        if input.value.empty?
          input.value
        elsif input.value[0].value == 'apply'
          coll = eval_ast(input.value[-1], env) || Hamster::Vector[]

          # evaluate the last argument
          sexp = RubyLisp::List.new(input.value.fill(coll, -1, 1))
          # assert that it's enumerable
          assert_arg_type sexp, 'last', Enumerable

          # drop `apply` and pull the last form's contents into the sexp as
          # multiple arguments
          all_but_last_arg = sexp.value[1..-2].map {|arg| eval_ast arg, env}
          fn, *args = all_but_last_arg + coll.to_list
          sexp = RubyLisp::List.new([RubyLisp::Symbol.new("apply"), fn])
          assert_arg_type sexp, 1, Proc
          fn.call(*args)
        elsif input.value[0].value == 'def'
          assert_arg_type input, 1, RubyLisp::Symbol
          key, val = input.value[1..-1]
          env.set key.value, eval_ast(val, env)
        elsif input.value[0].value == 'do'
          body = input.value[1..-1]
          body.map {|form| eval_ast(form, env)}.last
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

          ampersand_indices = bindings.value.to_list.indices {|x| x.value == '&'}
          if ampersand_indices.any? {|i| i != bindings.value.count - 2}
            raise RubyLisp::RuntimeError,
                  "An '&' can only occur right before the last binding."
          end

          fn = lambda do |*args|
            inner_env = RubyLisp::Environment.new(outer: env)
            inner_env.set(fn_name, fn) # self-referential lambda omg

            sexp = RubyLisp::List.new([RubyLisp::Symbol.new(fn_name), *args])
            if bindings.value.any? {|binding| binding.value == '&'}
              required_args = bindings.value.count - 2
              assert_at_least_n_args sexp, required_args

              bindings.value[0..-3].zip(args.take(required_args)).each do |k, v|
                inner_env.set(k.value, v)
              end

              rest_args = if args.count > required_args
                            args[required_args..-1].to_list
                          else
                            nil
                          end

              inner_env.set(bindings.value[-1].value, rest_args)
            else
              required_args = bindings.value.count
              assert_number_of_args sexp, required_args

              bindings.value.zip(args).each do |k, v|
                inner_env.set(k.value, v)
              end
            end

            body.map {|form| eval_ast(form, inner_env)}.last
          end
        elsif input.value[0].value == 'if'
          cond, then_form, else_form = input.value[1..-1]
          unless then_form
            raise RubyLisp::RuntimeError,
                  "An `if` form must at least have a 'then' branch."
          end

          if (eval_ast cond, env)
            eval_ast(then_form, env)
          elsif else_form
            eval_ast(else_form, env)
          end
        elsif input.value[0].value == 'in-ns'
          assert_number_of_args input, 1
          input.value[1] = eval_ast(input.value[1], env)
          assert_arg_type input, 1, RubyLisp::Symbol
          ns_name = input.value[1].to_s
          # TODO: register ns and switch to it
          env.namespace = ns_name
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

          body.map {|form| eval_ast(form, inner_env)}.last
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
          env.namespace = ns_name
        elsif input.value[0].value == 'quote'
          assert_number_of_args input, 1
          fn, *args = input.value
          quoted_form = args[0]

          if [RubyLisp::HashMap, RubyLisp::List, RubyLisp::Vector].member? quoted_form.class
            quoted_form.quote.value
          else
            quoted_form.quote
          end
        elsif input.value[0].value == 'resolve'
          assert_number_of_args input, 1
          symbol = eval_ast(input.value[1], env)
          sexp = RubyLisp::List.new(input.value.fill(symbol, 1, 1))
          assert_arg_type sexp, 1, RubyLisp::Symbol
          symbol.resolve(env)
        else
          fn, *args = input.value.map {|value| eval_ast(value, env)}
          fn.call(*args)
        end
      when RubyLisp::Symbol
        if input.quoted
          input
        else
          input.resolve(env)
        end
      when RubyLisp::Vector
        input.value.map {|value| eval_ast(value, env)}
      else
        input.value
      end
    end
  end
end
