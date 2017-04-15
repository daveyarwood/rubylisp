module RubyLisp
  module Util
    module_function

    def assert_number_of_args sexp, num_args
      fn, *args = sexp
      fn_name = fn.value
      unless args.count == num_args
        raise RuntimeError,
              "Wrong number of arguments passed to `#{fn_name}`; " +
              "got #{args.count}, expected #{num_args}."
      end
    end

    def assert_at_least_n_args sexp, num_args
      fn, *args = sexp
      fn_name = fn.value
      unless args.count >= num_args
        raise RuntimeError,
              "Wrong number of arguments passed to `#{fn_name}`; " +
              "got #{args.count}, expected at least #{num_args}."
      end
    end

    def assert_arg_type sexp, arg_number, arg_type
      fn = sexp[0]
      fn_name = fn.value
      arg = if arg_number == 'last'
              sexp.last
            else
              sexp[arg_number]
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
        raise RuntimeError,
              "#{arg_description} to `#{fn_name}` must be a " +
              "#{expected}; got a #{arg.class}."
      end
    end

  end
end
