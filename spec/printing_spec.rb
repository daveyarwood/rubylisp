require 'spec_helper'

RSpec.describe 'pr-str' do
  with_rubylisp_env do
    expect_outputs \
      '""', '(pr-str)',
      '"\"\""', '(pr-str "")',
      '"\"abc\""', '(pr-str "abc")',
      '"\"abc  def\" \"ghi jkl\""', '(pr-str "abc  def" "ghi jkl")',
      '"\"\\\\\"\""', '(pr-str "\"")',
      '"(1 2 \"abc\" \"\\\\\"\") \"def\""', '(pr-str (list 1 2 "abc" "\"") "def")',
      '"\"abc\\\ndef\\\nghi\""', '(pr-str "abc\ndef\nghi")',
      '"\"abc\\\\\\\\def\\\\\\\\ghi\""', '(pr-str "abc\\\\def\\\\ghi")',
      '"()"', '(pr-str (list))',
      '"[]"', '(pr-str [])',
      '"[1 2 \"abc\" \"\\\\\"\"] \"def\""', '(pr-str [1 2 "abc" "\""] "def")'
  end
end

RSpec.describe 'prn' do
  with_rubylisp_env do
    expect_outputs \
      "\nnil", '(prn)',
      "\"abc\"\nnil", '(prn "abc")',
      "\"abc  def\" \"ghi jkl\"\nnil", '(prn "abc  def" "ghi jkl")',
      "\"\\\"\"\nnil", '(prn "\"")',
      "\"abc\\ndef\\nghi\"\nnil", '(prn "abc\ndef\nghi")',
      "\"abc\\\\def\\\\ghi\"\nnil", '(prn "abc\\\\def\\\\ghi")',
      "(1 2 \"abc\" \"\\\"\") \"def\"\nnil", '(prn (list 1 2 "abc" "\"") "def")'
  end
end

RSpec.describe 'println' do
  with_rubylisp_env do
    expect_outputs \
      "\nnil", '(println)',
      "\nnil", '(println "")',
      "abc\nnil", '(println "abc")',
      "abc  def ghi jkl\nnil", '(println "abc  def" "ghi jkl")',
      "\"\nnil", '(println "\"")',
      "abc\ndef\nghi\nnil", '(println "abc\ndef\nghi")',
      "abc\\def\\ghi\nnil", '(println "abc\\\\def\\\\ghi")',
      "(1 2 abc \") def\nnil", '(println (list 1 2 "abc" "\"") "def")'
  end
end

