require 'readline'
require 'irb'
MAKE = :runc
WORKSPACE = {}

def execute
  fname = ENV["r_pre"] || "__pre__"
  r = IO.read(fname)
  cname = "__app__.c"
  IO.write cname, 
	r.sub("$$", combine(:text, "\n"))
         .sub("$G", combine(:global, "\n"))
  send MAKE, cname
end

Runner = ENV["r_runner"] || (RUBY_DESCRIPTION[/linux/] ? "./makecmd" : "makecmd")

def space(key)
    WORKSPACE[key] ||= []
end

def each(key)
    space(key).each{|x| yield x }
end

def add(key, value)
    space(key) << value
end

def addall(key, value)
    space(key).concat value
end

def remove(key, value)
    space(key).delete(value)
end

def has(key, value)
    space(key).include?(value)
end

def set(key, value)
    space(key).replace value
end

def clear(key)
    space(key).clear
end

def pop(key)
    space(key).pop
end

def combine(key, delim)
    space(key).join(delim)
end


def runc(name)
  ENV['import'] = space(:source).join(" ")
  ENV['main'] =  name
  raise "A" unless system ENV.to_h, Runner
end

def prompt
 if has(:set, :multiline)
     "....>"
 else
    (space(:source) + ["~> "]).join(" ")
 end
end

IDENTIFIER = /[A-Za-z_][A-Za-z0-9_]*/

COMPLETPROC = lambda{|x|
    space(:complete).select{|y| y.start_with?(x) || y.sub(/^\s*/, "").start_with?(x) } + Dir.glob(x + "*").to_a
}

def update_one(s)
    r = s.scan(IDENTIFIER).to_a.uniq
    space(:complete).concat r
    space(:complete).uniq!
end

def update_completion
    clear(:complete)
    each(:source){|y|
        update_one File.read y if FileTest.file?(y)
    }
    Readline::HISTORY.each{|y|
        update_one(y)
    }
end

def multiline(head)
  rr = [head]
  Readline::HISTORY.pop
  add(:set, :multiline)
  loop do
    r = Readline.readline(prompt, true)
    Readline::HISTORY.pop
    rr.push r
    break if r == ""
  end
  line = rr.join("\n")
  Readline::HISTORY.push line
  remove(:set, :multiline)
  line
end


def readline
   loop do
     r = Readline.readline(prompt, true)
     if r[0] == ' ' && r[1] == ' '
      return multiline r[2..-1]
     end
     if r == ""
       next
     end
     return r
   end
end
old = ""
Readline.completion_proc = COMPLETPROC
update_completion
while r = readline
  case r
  when /^\+([\w\W]*)/
    add :source, $1.strip
    set :source, space(:source).join(" ").split(/[\n ]/)
  when /^#([\w\W]*)/
    add :global, $1.strip    
  when /^\-([\w\W]*)/
    remove :source, $1.strip
    set :source, space(:source).join(" ").split(/[\n ]/)
  when /^\^([\w\W]*)/
    remove :global, $1.strip
  #when /^:irb\b/
  #  binding.irb
  when /^:reset\b([\w\W]*)/
    r = $1
    clear(:text)
    if r.include?("all") || r.include?("source")
        clear(:source)
    end
    if r.include?("all") || r.include?("global")
        clear(:global)
    end
  else 
    if r[0] == '?'
      retract = true
      r = r[1..-1]
    end
    add :text, r
    begin 
      execute
      IO.write "old.txt", old
      x = `git diff old.txt repl.txt`
      puts x.split("\n").select{|x| x[0] == "+" && x[0..2] != "+++"}.map{|x| x[1..-1]}
      if retract
          pop :text
      else
          old = File.read "repl.txt"
      end
    rescue
      puts File.read("err.txt").force_encoding("GBK")
      pop :text
    end
  end
  update_completion
end
