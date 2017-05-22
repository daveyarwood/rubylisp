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

def with_out_str
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
    actual = with_out_str do
      result = RubyLisp::Parser.parse input, $rubylisp_env
      print result
    end

    if expected.class == Regexp
      expect(expected).to match(actual)
    else
      expect(actual).to eq(expected)
    end
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

def with_tmp_file contents
  rand_id = "#{DateTime.now.strftime('%Q')}-#{rand(10000)}"
  filename = "/tmp/rubylisp-test-#{rand_id}.txt"
  tmp_file = File.new filename, 'w+'
  tmp_file.write contents
  tmp_file.close
  yield tmp_file
end
