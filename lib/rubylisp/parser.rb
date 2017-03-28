require 'parslet'

RLInt = Struct.new(:int) do
  def eval
    int.to_i
  end
end

RLKw = Struct.new(:kw) do
  def eval
    kw.to_sym
  end
end

RLMessage = Struct.new(:message) do
  # TODO: resolve message as a value
  def eval
    self
  end
end

RLSexp = Struct.new(:op, :args) do
  # TODO: apply op to args
  def eval
    RLSexp.new(op.eval, args.map(&:eval))
  end
end

RLStr = Struct.new(:string) do
  def eval
    self
  end
end

RLSymbol = Struct.new(:symbol) do
  # TODO: resolve symbol to a value
  def eval
    self
  end
end

module RubyLisp
  class Parser < Parslet::Parser
    root(:string)

    rule(:exprs)       { expr.repeat(1) }
    rule(:expr)        { (int | kw | string | symbol | sexp) >> ows }

    rule(:int)         { match('[0-9]+').as(:int) }
    rule(:kw)          { colon >> match('[a-zA-Z0-9_\-!?#$%&*]').repeat(1).as(:kw) }

    rule(:string)      { str('"') >>
                         str_content.repeat(0).as(:string)
                         str('"') }
    rule(:str_content) { str('"').absent? >> match('.|\n|\r|\\"') }

    rule(:symbol)      { ident.as(:symbol) | message }
    rule(:message)     { str('.') >> ident.as(:message) }

    rule(:sexp)        { lparen >> ows >>
                         (expr.as(:op) >> (expr.repeat(0).as(:args))).maybe >>
                         ows >> rparen }

    rule(:ident) { match('[a-z]').repeat(2) }

    # rule(:ident)       { match('[^0-9\(\)\[\]\{\}\.,;"]') >>
    #                      match('[a-zA-Z0-9_\-!?#$%&*]').repeat(0) }

    rule(:colon)       { str(':') }
    rule(:lparen)      { str('(') }
    rule(:rparen)      { str(')') }

    rule(:ows)         { match('\s').repeat(1).maybe }
  end

  class Transformer < Parslet::Transform
    rule(expr: simple(:expr))                   { RLExpr.new(expr) }
    rule(int: simple(:int))                     { RLInt.new(int) }
    rule(kw: simple(:kw))                       { RLKw.new(kw) }
    rule(string: simple(:string))               { RLStr.new(string) }
    rule(message: simple(:message))             { RLMessage.new(message) }
    rule(op: simple(:op), args: subtree(:args)) { RLSexp.new(op, args) }
    rule(symbol: simple(:symbol))               { RLSymbol.new(symbol) }
  end
end

