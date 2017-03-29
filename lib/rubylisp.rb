require 'rubylisp/repl'
require 'rubylisp/version'

module RubyLisp
  module_function

  def parse input
    "TODO: mkparser"
  end

  def run_file filename
    contents = File.read filename
    parsed = parse contents
    p parsed
  end
end
