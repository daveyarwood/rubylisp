# RubyLisp

A Lisp dialect of Ruby.

## Why?

Lisps are great, but I haven't found one usable enough (by my own standards) for scripting. [Clojure][clojure] is my favorite language from a design perpective, and the fact that you can leverage existing JVM libraries is super convenient. But there's just one problem -- its startup time is _so slow_.

[Common Lisp][commonlisp] is nice; it's a powerful Lisp, and it's fast. But it's not always
easy to find X existing library to do Y thing, it's maybe a little too
low-level for my liking, and the tooling situation is not so great.

[Ruby][ruby] is great for scripting, cross-platform, and has hella good libraries, but there's just one problem -- it's not a Lisp.

I've played around with the [make-a-lisp][mal] guide a few times in the past to
build Lisps for fun in languages like Rust. I thought it would be interesting to
try and build for myself the convenient scripting Lisp that I always wanted. It turns out that it's super easy to write a Lisp interpreter, but it's awful time-consuming to build a whole language from scratch. I had a shower thought that the Ruby standard library can already do about 80% of the things a faithful Lisp should do, so maybe the path of least resistance to building the Lisp of my dreams is to write the interpreter in Ruby and totally cheat on all of the function implementations by delegating to functions and types that have already been implemented in the Ruby stdlib.

I think I was right. Check it out, everyone -- you can write your Ruby scripts in Lisp now!

## Features

> NOTE: RubyLisp is still in early development. If you find something is broken
> or missing, please file an issue, or better yet, fork this repo, add/fix it
> yourself, and make a Pull Request!

* Syntax and stdlib functions heavily influenced by Clojure.
* Easy, convenient Ruby inter-op.
* Fire up a REPL or run it in a script.
* Immutable linked lists, vectors, and hashes courtesy of the [Hamster][hamster]
  library.
* _(TODO)_ Macros, Clojure-style.
* _(TODO)_ Namespaces, Clojure-style.
* _(TODO)_ Dependency management / the ability to use some sort of build tool to
  include Ruby libraries and use them via inter-op.

## Examples

_TODO_

## Installation

Run this:

```bash
$ gem install rubylisp
```

## Usage

To start a REPL:

```bash
$ rbl
```

To interpret a file containing RubyLisp code:

```bash
$ rbl my_sweet_rubylisp_script.rbl
```

Or, if you'd like, you can include a shebang, make the script executable and run it directly:

```
$ cat << EOF > reticulate_splines.rbl
#!/usr/bin/env rbl
(print "Reticulating splines... ")
(Kernel::sleep 2)
(println "done.")
EOF

$ chmod +x reticulate_splines.rbl

$ ./reticulate_splines.rbl
Reticulating splines... done.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Contributions welcome!

As a general rule, I want RubyLisp to mirror the behavior of Clojure as closely
as possible. If you have a favorite Clojure function/macro and it isn't included
in RubyLisp yet, why not add it yourself and make a Pull Request? :)

## License

Copyright © 2017 Dave Yarwood

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[clojure]: https://clojure.org
[commonlisp]: https://en.wikipedia.org/wiki/Common_Lisp
[ruby]: http://ruby-lang.org
[mal]: https://github.com/kanaka/mal
[hamster]: https://github.com/hamstergem/hamster
