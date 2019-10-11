require 'readline'
SOURCE = []
MAKE = :runc
TEXT = []
GLOBAL = []
def execute
  fname = ENV["r_pre"] || "__pre__"
  r = IO.read(fname)
  cname = "__app__.c"
  IO.write cname, 
	r.sub("$$", TEXT.join("\n"))
         .sub("$G", GLOBAL.join("\n"))
  send MAKE, cname
end

Runner = ENV["r_runner"] || (RUBY_DESCRIPTION[/linux/] ? "./makecmd" : "makecmd")

def runc(name)
  ENV['import'] = SOURCE.join(" ")
  ENV['main'] =  name
  raise "A" unless system ENV.to_h, Runner
end

def prompt
 (SOURCE + ["~> "]).join(" ")
end

old = ""

while (r = Readline.readline(prompt, true))
  case r
  when /^\+(.*)/
    SOURCE << $1.strip
  when /^#(.*)/
    GLOBAL << $1.strip
  when /^\-(.*)/
    SOURCE.delete $1
  when /^\^(.*)/
    GLOBAL.delete $1
  when /^:reload (.*)/
    r = $1
    TEXT.clear
    if r.include?("all") || r.include?("source")
      SOURCE.clear
    end
    if r.include?("all") || r.include?("source")
      GLOBAL.clear
    end
  
  else 
    if r[0] == '?'
      retract = true
      r = r[1..-1]
    end
    TEXT << r
    begin 
      execute
      IO.write "old.txt", old
      x = `git diff old.txt repl.txt`
      puts x.split("\n").select{|x| x[0] == "+" && x[0..2] != "+++"}.map{|x| x[1..-1]}
      old = File.read "repl.txt"
      TEXT.pop if retract
    rescue 
      puts File.read("err.txt").force_encoding("GBK")
      TEXT.pop
    end
  end
end
