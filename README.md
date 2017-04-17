# RubyLisp (rbl)

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
* Clojure-style atoms, courtesy of [concurrent-ruby][concurrent].
* _(TODO)_ Clojure-style macros.
* _(TODO)_ Clojure-style namespaces.
* _(TODO)_ Dependency management / the ability to use some sort of build tool to
  include Ruby libraries and use them via inter-op.

## Examples

### It's basically Clojure

Many of the affordances of the Clojure standard library are implemented as part
of the `rbl.core` namespace, which is included by default:

```clojure
user> (prn 'oh :hello "hi" 1 2.3 '(abc def) ['g ()] '{:h ijk})
oh :hello "hi" 1 2.3 (abc def) [g ()] {:h ijk}
nil

user> (take 20 (map inc (reverse (range 100))))
(101 100 99 98 97 96 95 94 93 92 91 90 89 88 87 86 85 84 83 82)
```

### Module/Class members

Members of Ruby modules and classes may be accessed in a familiar way, by appending `::` to the module or class:

```clojure
user> Kernel::ARGV
[]

user> Encoding::Converter::CR_NEWLINE_DECORATOR
8192

user> File::SEPARATOR
"/"
```

### Instance methods

Instance methods are called like Lisp functions. The reader will recognize any symbol that starts with `.` as an instance method, and send it as a message to the second element in the S-expression.

For example, `(.+ 1 2)` in RubyLisp is equivalent to `1.send(:+, 2)` in Ruby.

```clojure
user> (def f (File::open "/tmp/ugh.txt"))
#<File:/tmp/ugh.txt>

user> (.methods f)
[:size :path :truncate :lstat :atime :mtime :ctime :birthtime :chmod :chown ...
:! :== :!= :__send__ :equal? :instance_eval :instance_exec :__id__]

user> (.readbyte f)
66

user> (.size f)
365
```

### Immutable lists

The `list` function and `quote` form (e.g. `'(1 2 3)`) create immutable lists from the [Hamster][hamster] library:

```clojure
user> (class (list 1 2 3))
Hamster::Cons

user> (class '(abc def))
Hamster::Cons

user> (cons 'foo (quote (bar baz)))
(foo bar baz)
```

### Immutable vectors

Similarly, the `vector` and `vec` functions, as well as the square bracket literal form, create immutable vectors:

```clojure
user> (vector 1 2 3)
[1 2 3]

user> (vec (list 1 2 3))
[1 2 3]

user> (= [1 2 3] (vector 1 2 3))
true

user> (class [1 2 3])
Hamster::Vector
```

### Immutable maps

The `hash-map` function or the curly brace literal form can be used to create an immutable map:

```clojure
user> (map? (hash-map 'a 1 'b 2 'c 3))
true

user> {:a 1 "b" 2 'C 3}
{:a 1, C 3, "b" 2}
```

### Keywords (a.k.a. Symbols)

A keyword (in Clojure and therefore RubyLisp parlance) begins with a `:`. In Ruby, this data type is called, somewhat confusingly, a Symbol.

```clojure
user> (class :floop)
Symbol

user> (= :snoob (.to_sym "snoob"))
true
```

RubyLisp monkey-patches the Symbol class to make it behave like a Clojure keyword; you can call it like a function in order to retrieve a value from a hash map:

```clojure
user> (def barbara {:age 7 :species "greyhound"})
{:age 7, :species "greyhound"}

user> (:species barbara)
"greyhound"
```

### Instance variables

But that's not all -- you can also use keywords to get the value of an instance variable:

```clojure
;; FIXME: This is a contrived example because it is not yet possible to easily
;; define a class in RubyLisp.

;; rbl.core/=@ is provided as a convenient way to set instance variables on any
;; object... even a string!
user> (def s "my string")
"my string"

user> (=@ s :object_level 9001)
9001

;; instance variables can then be retrieved by using a keyword as a function
user> (:object_level s)
9001
```

The above example is a little nonsensical (although a testament to the whimsy
of Ruby), but the pair of `=@` and keyword-used-as-a-function will be more
useful once there is a convenient way to define classes in RubyLisp.

### Mutable arrays and hashes

You can still use Ruby's mutable data structures via inter-op, if you insist:

```clojure
user> (def a (.dup (.to_a [1 2 3 4 5])))
[1 2 3 4 5]

user> (class a)
Array

user> (.<< a 6)
[1 2 3 4 5 6]

user> a
[1 2 3 4 5 6]

user> (def h (.to_h {}))
{}

user> (class h)
Hash

user> (.merge! h {:a 3})
{:a 3}

user> h
{:a 3}
```

## Installation

Run this:

```bash
$ gem install rbl
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
[concurrent]: https://github.com/ruby-concurrency/concurrent-ruby
