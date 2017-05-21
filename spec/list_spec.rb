require 'spec_helper'

RSpec.describe 'list functions' do
  with_rubylisp_env do
    expect_outputs \
      '()', '(list)',
      'true', '(list? (list))',
      'true', '(empty? (list))',
      'false', '(empty? (list 1))',
      '(1 2 3)', '(list 1 2 3)',
      '3', '(count (list 1 2 3))',
      '0', '(count (list))',
      '0', '(count nil)',

      '[]', '[]',
      '[1 2 3]', '[1 2 3]',
      'false', '(list? [])',
      'false', '(list? [4 5 6])',
      'true', '(empty? [])',
      'false', '(empty? [1])',
      '3', '(count [1 2 3])',
      '0', '(count [])'
  end
end
