require "bundler/setup"
require "rubylisp/environment"
require "rubylisp/parser"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def with_captured_stdout
  old_stdout = $stdout
  $stdout = StringIO.new('', 'w')
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end

def with_rubylisp_env
  $rubylisp_env = RubyLisp::Environment.new(namespace: 'user').stdlib
  yield
end

def expect_output expected, input
  it "correctly handles #{input}" do
    actual = with_captured_stdout do
      result = RubyLisp::Parser.parse input, $rubylisp_env
      print result
    end
    expect(actual).to eq(expected)
  end
end

def expect_outputs *args
  args.each_slice(2) do |(expected, input)|
    expect_output expected, input
  end
end

def expect_error expected, input
  it "should throw an error when given #{input}" do
    expect { RubyLisp::Parser.parse input, $rubylisp_env }.to raise_error(expected)
  end
end
