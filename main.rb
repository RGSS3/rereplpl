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

def runc(name)
  ENV['import'] = SOURCE.join(" ")
  ENV['main'] =  name
  `makerun`
end

print "] "
a = 0
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
    TEXT << r
    r = execute
    s = r[/!!CPBEGIN#{a}\n([\w\W]*)\n!!CPEND#{a}/, 1]
    puts s if s
  end
  print (SOURCE.join(" ") + "] ")
  a += 1
end
