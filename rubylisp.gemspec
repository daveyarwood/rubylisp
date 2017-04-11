# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubylisp/version'

Gem::Specification.new do |spec|
  spec.name          = "rubylisp"
  spec.version       = RubyLisp::VERSION
  spec.authors       = ["Dave Yarwood"]
  spec.email         = ["dave.yarwood@gmail.com"]

  spec.summary       = "A Lisp dialect of Ruby"
  spec.description   = "A Lisp dialect of Ruby"
  spec.homepage      = "https://github.com/daveyarwood/rubylisp"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "http://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_runtime_dependency 'hamster', '3.0.0'
end
