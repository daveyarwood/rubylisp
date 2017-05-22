require 'spec_helper'

RSpec.describe "ARGV" do
  with_rubylisp_env do
    expect_outputs \
      'true', '(= Kernel::Array (class Kernel::ARGV))',
      '[]', 'Kernel::ARGV'
  end
end
