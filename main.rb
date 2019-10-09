SOURCE = []
MAKE = :runc
TEXT = []
GLOBAL = []
def execute
  fname = "__pre__"
  r = IO.read(fname)
  cname = "__app__.c"
  IO.write cname, 
	r.sub("$$", TEXT.map.with_index{|x, i| 
"CPBEGIN(#{i})
#{x}
CPEND(#{i})
"}.join)
         .sub("$G", GLOBAL.join("\n"))
  send MAKE, cname
end

Runner = RUBY_DESCRIPTION[/linux/] ? "./makecmd" : "makecmd"

def runc(name)
  ENV['import'] = SOURCE.join(" ")
  ENV['main'] =  name
  raise "A" unless system ENV.to_h, Runner
end

print "~> "
while (r = gets)
  r = r.chomp("\n")
  case r
  when /^\+(.*)/
    SOURCE << $1.strip
  when /^#(.*)/
    GLOBAL << $1.strip
  when /^\-(.*)/
    SOURCE.delete $1
  when /^\^(.*)/
    GLOBAL.delete $1
  when /^:reload /
    TEXT.clear
  else 
    if r[0] == '?'
      retract = true
      r = r[1..-1]
    end
    TEXT << r
    begin 
      execute
      r = File.read "repl.txt"
      a = TEXT.size - 1
      ss = []
      r.scan(/!!CPBEGIN#{a}!!([\w\W]*)!!CPEND#{a}!!/).each{|a, b|
          ss << a if a
      }
      if ss.size == 1
          puts ss[0]
      else
          ss.each_with_index{|x, i|
            puts "#{i+1}. #{x}"
          }
      end
      TEXT.pop if retract
    rescue 
      puts File.read "err.txt"
      TEXT.pop
    end

  end
  print((SOURCE + ["~> "]).join(" "))
end
