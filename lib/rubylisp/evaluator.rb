require 'rubylisp/environment'
require 'rubylisp/printer'
require 'rubylisp/types'
require 'rubylisp/util'

include RubyLisp::Util

module RubyLisp
  module Evaluator
    module_function

    def macro_call? ast, env
      return false unless ast.is_a? Hamster::List
      symbol = ast[0]
      return false unless symbol.class == Symbol
      return false unless env.find(symbol.value)
      value = symbol.resolve(env)
      value.class == Function && value.is_macro
    end

    def macroexpand input, env
      while macro_call? input, env
        macro = input[0].resolve(env)
        input = macro.call(*input[1..-1])
      end
      input
    end

    def pair? form
      sequential?(form) && form.count > 0
    end

    def quasiquote ast
      if !pair?(ast)
        list [Symbol.new('quote'), ast]
      elsif vector? ast
        list [Symbol.new('vec'), quasiquote(ast.to_list)]
      else
        elem_a, *elems = ast

        if elem_a.class == Symbol && elem_a.value == 'unquote'
          elems[0]
        elsif pair?(elem_a) &&
              elem_a[0].class == Symbol &&
              elem_a[0].value == 'splice-unquote'
          list [Symbol.new('concat'), elem_a[1], quasiquote(elems)]
        else
          list [Symbol.new('cons'),
                quasiquote(elem_a),
                quasiquote(elems.to_list)]
        end
      end
    end

    def special_form? input, name
      input[0].class == Symbol && input[0].value == name
    end

    def eval_ast input, env
      # loop forever until a value is returned;
      # this is for tail call optimization
      while true
        # (no-op if this is not a macro call)
        input = macroexpand(input, env)

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
        when Hamster::Hash
          return input.map {|k, v| [eval_ast(k, env), eval_ast(v, env)]}
        when Hamster::List
          if input.empty?
            return input
          elsif special_form? input, 'apply'
            # evaluate the last argument
            coll = eval_ast(input[-1], env) || vector()
            # assert that it's enumerable
            sexp = list input.fill(coll, -1, 1)
            assert_arg_type sexp, 'last', Enumerable

            # drop `apply` and pull the last form's contents into the sexp as
            # multiple arguments
            all_but_last_arg = sexp[1..-2].map {|arg| eval_ast arg, env}
            fn, *args = all_but_last_arg + coll.to_list
            sexp = list [Symbol.new("apply"), fn]
            assert_arg_type sexp, 1, [Function, Proc]
            return fn.call(*args)
          # Provides a way to call a Ruby method that expects a block. Blocks
          # are not first-class in Ruby, but they have similar semantics to
          # functions.
          #
          # The last argument to call-with-block can be a Function or
          # Proc that takes any number of arguments; it will be provided to the
          # instance method as a block.
          #
          # ruby: instance.method(arg1, arg2, arg3) { do_something }
          # rbl: (call-with-block .method instance [arg1 arg2 arg3] fn)
          elsif special_form? input, 'call-with-block'
            assert_number_of_args input, 4

            assert_arg_type input, 1, Symbol

            sexp = input[2..-1].map {|form| eval_ast(form, env)}
                               .cons(input[1].value[1..-1].to_sym)
                               .cons(input[0])

            assert_arg_type sexp, 3, [Hamster::List, Hamster::Vector]
            assert_arg_type sexp, 4, [Function, Proc]

            method, receiver, method_args, fn = sexp[1..-1]

            return receiver.send(method, *method_args) do |*block_args|
              fn.call(*block_args)
            end
          elsif special_form? input, 'def'
            assert_arg_type input, 1, Symbol
            k, v = input[1..-1]
            key, val = [k.value, eval_ast(v, env)]
            return env.out_env.set key, val
          elsif special_form? input, 'defmacro*'
            assert_arg_type input, 1, Symbol
            key, val = input[1..-1]
            macro = eval_ast(val, env)
            macro.is_macro = true
            return env.set key.value, macro
          elsif special_form? input, 'do'
            body = input[1..-1]
            # discard the return values of all but the last form
            body[0..-2].each {|form| eval_ast(form, env)}
            # recur; evaluate and return the last form
            input = body.last
          elsif special_form? input, 'eval'
            assert_number_of_args input, 1

            form = eval_ast(input[1], env)
            input = form
          elsif special_form? input, 'fn'
            if input[1].class == Symbol
              fn_name = input[1].value
              more = input[2..-1]
            else
              fn_name = "__fn_#{rand 10000}"
              more = input[1..-1]
            end

            arities = more[0].class == Hamster::Vector ? [list(more)] : more

            return fn = Function.new(fn_name, env, arities) {|*fn_args|
              arity = fn.get_arity(fn_args)
              eval_ast arity.body, fn.gen_env(arity, fn_args, env)
            }
          elsif special_form? input, 'if'
            unless input[1..-1].count > 1
              raise RuntimeError,
                    "An `if` form must at least have a 'then' branch."
            end

            cond, then_form, else_form = input[1..-1]

            if (eval_ast cond, env)
              input = then_form
            elsif else_form
              input = else_form
            else
              return nil
            end
          elsif special_form? input, 'in-ns'
            assert_number_of_args input, 1
            input[1] = eval_ast(input[1], env)
            assert_arg_type input, 1, Symbol
            ns_name = input[1].to_s
            # TODO: register ns and switch to it
            env.is_namespace = true
            return env.namespace = ns_name
          elsif special_form? input, 'let'
            assert_arg_type input, 1, Hamster::Vector
            inner_env = Environment.new(outer: env)
            bindings, *body = input[1..-1]
            unless bindings.count.even?
              raise RuntimeError,
                    "The bindings vector of `let` must contain an even number " +
                    " of forms."
            end

            bindings.each_slice(2) do |(binding, value)|
              inner_env.set binding.value, eval_ast(value, inner_env)
            end

            # discard the return values of all but the last form
            body[0..-2].each {|expr| eval_ast(expr, inner_env)}
            # recur; evaluate and return the last form's value
            env = inner_env
            input = body.last
          elsif special_form? input, 'macroexpand'
            assert_number_of_args input, 1
            form = eval_ast(input[1], env)
            return macroexpand(form, env)
          elsif special_form? input, 'ns'
            # ns will be defined more robustly in rbl.core, but rbl.core also
            # needs the `ns` form in order to declare that it is rbl.core.
            #
            # defining it here in a minimal form where it is equivalent to in-ns,
            # except that you don't have to quote the namespace name
            assert_number_of_args input, 1
            assert_arg_type input, 1, Symbol
            ns_name = input[1].to_s
            # TODO: register ns and switch to it
            env.is_namespace = true
            return env.namespace = ns_name
          elsif special_form? input, 'quasiquote'
            assert_number_of_args input, 1
            ast = input[1]
            input = quasiquote(ast)
          elsif special_form? input, 'quote'
            assert_number_of_args input, 1
            return input[1]
          elsif special_form? input, 'resolve'
            assert_number_of_args input, 1
            symbol = eval_ast(input[1], env)
            sexp = list input.fill(symbol, 1, 1)
            assert_arg_type sexp, 1, Symbol
            return symbol.resolve(env)
          else
            fn, *args = input.map {|value| eval_ast(value, env)}
            if fn.class == Function
              # recur with input and env set to the body of the function and an
              # inner environment where the function's bindings are set to the
              # values of the arguments
              arity = fn.get_arity(args)
              env = fn.gen_env(arity, args, env)
              input = arity.body
            else
              return fn.call(*args)
            end
          end
        when Hamster::Vector
          return input.map {|value| eval_ast(value, env)}
        when Symbol
          return input.resolve(env)
        when Value
          return input.value
        else
          return input
        end
      end
    end
  end
end
