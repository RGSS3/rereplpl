SOURCE = []
MAKE = :runc
TEXT = []
TEXT2 = []
GLOBAL = []
def execute
  fname = "__pre__"
  r = IO.read(fname)
  cname = "__app__.c"
  IO.write cname, 
	r.sub("$$", TEXT.join("\n") + "\n" + TEXT2.join("\n"))
         .sub("$G", GLOBAL.join("\n"))
  send MAKE, cname
end

def runc(name)
  ENV['import'] = SOURCE.join(" ")
  ENV['main'] =  name
  system "makerun"
end

print "] "
@a = 0
while (r = gets)
  r = r.chomp("\n")
  @a += 1
  case r
  when /^\+(.*)/
    SOURCE << $1.strip
  when /^#(.*)/
    GLOBAL << $1.strip
  when /^\-(.*)/
    SOURCE.delete $1
  when /^>>(.*)/
    TEXT << $1
    execute
  when /^>(.*)/
    TEXT << $1
  when /^:reload /
    TEXT.clear
    TEXT2.clear
    SOURCE.clear
  else 
    TEXT2 << r
    execute
    TEXT2.clear
  end
  print (SOURCE.join(" ") + "] ")
end
