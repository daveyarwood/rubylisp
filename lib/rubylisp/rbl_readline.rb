# adapted from: https://github.com/kanaka/mal/blob/master/ruby/mal_readline.rb
require 'fileutils'
require "readline"

$history_loaded = false
$histfile = "#{ENV['HOME']}/.rbl-history"

# create history file if it doesn't exist already
FileUtils.touch($histfile)

def _readline(prompt)
  if !$history_loaded && File.exist?($histfile)
    $history_loaded = true
    if File.readable?($histfile)
      File.readlines($histfile).each {|l| Readline::HISTORY.push(l.chomp)}
    end
  end

  if line = Readline.readline(prompt, true)
    history = Readline::HISTORY
    if line.strip.empty? || (history.length > 1 && (history[-2] == history[-1]))
      history.pop
    elsif File.writable?($histfile)
      File.open($histfile, 'a+') {|f| f.write(line+"\n")}
    end
    return line
  else
    return nil
  end
end
