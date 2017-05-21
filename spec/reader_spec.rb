require 'spec_helper'

RSpec.describe 'numbers' do
  with_rubylisp_env do
    expect_outputs \
      '1', '1',
      '7', '7',
      '-123', '-123'
  end
end

RSpec.describe 'symbols' do
  with_rubylisp_env do
    expect_outputs \
      '1', "'1",
      '+', "'+",
      'abc', "'abc",
      'abc5', "'abc5",
      'abc-def', "'abc-def"
  end
end

RSpec.describe 'lists' do
  with_rubylisp_env do
    expect_outputs \
      '(+ 1 2)', "'(+ 1 2)",
      '()', "()",
      '()', "'()",
      '(nil)', "'(nil)",
      '((3 4))', "'((3 4))",
      '(+ 1 (+ 2 3))', "'(+ 1 (+ 2 3))",
      '(+ 1 (+ 2 3))', "'( +   1   (+     2 3  )   )",
      '(* 1 2)', "'(* 1 2)",
      '(** 1 2)', "'(** 1 2)",
      '(* -3 6)', "'(* -3 6)",
      # test commas as whitespace
      '(1 2 3)', "'(1 2, 3,,,,),,"
  end
end

RSpec.describe 'vectors' do
  with_rubylisp_env do
    expect_outputs \
      '[+ 1 2]', "'[+ 1 2]",
      '[]', '[]',
      '[[3 4]]', '[[3 4]]',
      "[+ 1 [+ 2 3]]", "'[+ 1 [+ 2 3]]",
      '[+ 1 [+ 2 3]]', "'[ +   1   [+   2 3    ]   ]"
  end
end

RSpec.describe 'hash-maps' do
  with_rubylisp_env do
    expect_outputs \
      '{"abc" 1}', '{"abc" 1}',
      '{"a" {"b" 2}}', '{"a" {"b" 2}}',
      '{"a" {"b" {"c" 3}}}', '{"a" {"b" {"c" 3}}}',
      '{:a {:b {:cde 3}}}', '{    :a  {:b   {  :cde     3    } }}'
  end
end

RSpec.describe 'true, false and nil' do
  with_rubylisp_env do
    expect_outputs \
      'nil', 'nil',
      'true', 'true',
      'false', 'false'
  end
end

RSpec.describe 'strings' do
  with_rubylisp_env do
    expect_outputs \
      '""', '""',
      '"abc"', '"abc"',
      '"abc (with parens)"', '"abc (with parens)"',
      '"abc  def"', '"abc  def"',
      '"abc\"def"', '"abc\"def"',
      '"abc\ndef"', '"abc\ndef"',
      '"\""', '"\""',
      '"abc\ndef\nghi"', '"abc\ndef\nghi"',
      '"abc\\\def\\\ghi"', '"abc\\\def\\\ghi"'
  end
end

RSpec.describe 'keywords' do
  with_rubylisp_env do
    expect_outputs \
      ':kw', ':kw',
      '(:kw1 :kw2 :kw3)', "'(:kw1 :kw2 :kw3)"
  end
end

RSpec.describe 'comments' do
  with_rubylisp_env do
    expect_outputs \
      'nil', ';; whole line comment (not an exception)',
      '1', '1 ; comment after expression',
      '1', '1; comment after expression'
  end
end

RSpec.describe 'reader errors' do
  with_rubylisp_env do
    expect_error 'Unexpected EOF while parsing list.', '(1 2'
    expect_error 'Unexpected EOF while parsing vector.', '[1 2'
    expect_error 'Unexpected EOF while parsing hash-map.', '{1 2'
    expect_error 'Unexpected EOF while parsing string.', '"abc'
    expect_error 'Unexpected EOF while parsing list.', '(1 2'
    expect_error 'Unexpected EOF while parsing string.', '(1 "abc'
  end
end
