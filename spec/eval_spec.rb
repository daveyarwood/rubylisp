require 'spec_helper'

RSpec.describe 'read-string' do
  with_rubylisp_env do
    expect_outputs \
      '(1 2 (3 4) nil)', '(read-string "(1 2 (3 4) nil)")',
      '(+ 2 3)', '(read-string "(+ 2 3)")',
      '7', '(read-string "7 ;; comment")',
      'nil', '(read-string ";; comment")'
  end
end

RSpec.describe 'eval' do
  with_rubylisp_env do
    expect_outputs \
      '5', '(eval (read-string "(+ 2 3)"))'
  end
end

RSpec.describe 'slurp' do
  with_rubylisp_env do
    with_tmp_file "A line of text\n" do |txt_file|
      expect_output '"A line of text\n"', "(slurp \"#{txt_file.path}\")"
    end
  end
end

RSpec.describe 'load-file' do
  with_rubylisp_env do
    contents = <<-EOF
      (defn inc1 [a] (+ 1 a))
      (defn inc2 [a] (+ 2 a))
      (defn inc3 [a] (+ 3 a))
    EOF

    with_tmp_file contents do |inc|
      expect_outputs \
        '#<Function: inc3>', "(load-file \"#{inc.path}\")",
        '8', '(inc1 7)',
        '9', '(inc2 7)',
        '12', '(inc3 9)'
    end

    contents = <<-EOF
      ;; A comment in a file
      (defn inc4 [a] (+ 4 a))
      (defn inc5 [a] ; a comment after code
        (+ 5 a))

      (prn "incB.mal finished")
      "incB.mal return string"

      ;; ending comment
    EOF

    with_tmp_file contents do |incB|
      expect_outputs \
        "\"incB.mal finished\"\n\"incB.mal return string\"",
        "(load-file \"#{incB.path}\")",

        '11', '(inc4 7)',
        '12', '(inc5 7)'
    end

    contents = <<-EOF
      (def mymap {"a"
                  1})

      (prn "incC.mal finished")
      "incC.mal return string"
    EOF

    with_tmp_file contents do |incC|
      expect_outputs \
        "\"incC.mal finished\"\n\"incC.mal return string\"",
        "(load-file \"#{incC.path}\")",

        '{"a" 1}', 'mymap'
    end
  end
end
