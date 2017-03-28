require 'rubylisp/parser'
require 'rubylisp/version'

module RubyLisp
  module_function

  def parse input
    ast = Parser.new.parse input
    Transformer.new.apply(ast).map(&:eval)
  end
end
