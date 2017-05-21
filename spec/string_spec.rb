require 'spec_helper'

RSpec.describe 'str' do
  with_rubylisp_env do
    expect_outputs \
      '""', '(str)',
      '""', '(str "")',
      '"abc"', '(str "abc")',
      '"\""', '(str "\"")',
      '"1abc3"', '(str 1 "abc" 3)',
      '"abc  defghi jkl"', '(str "abc  def" "ghi jkl")',
      '"abc\ndef\nghi"', '(str "abc\ndef\nghi")',
      '"abc\\\\def\\\\ghi"', '(str "abc\\\\def\\\\ghi")',
      '"(1 2 abc \")def"', '(str (list 1 2 "abc" "\"") "def")',
      '"()"', '(str (list))',
      '"[]"', '(str [])',
      '"[1 2 abc \"]def"', '(str [1 2 "abc" "\""] "def")'
  end
end

