require 'readline'
require 'irb'
require 'yaml'

module Repl
end

class Resource
    def initialize(text, largs, filename)
        @data = YAML.load text
        @data["ARGS"] = largs || []
        @data["FILENAME"] = [filename]
        @current = @data["WS"]
        (@data["HISTORY"] || []).each {|x|
            Readline::HISTORY.push x
        }
    end

    def dump(fn)
        @data["HISTORY"] = Readline::HISTORY.length.times.map{|i|
            Readline::HISTORY[i]
        }
        if @data["FILENAME"][-1]
            IO.binwrite @data["FILENAME"][-1], YAML.dump(@data)
        end
    end

    class Runner
        def initialize(data)
            @data = data
        end
        def expand((a, b))
            IO.write b, _arr(a).map{|line| line.gsub(/\$<([^>]*)>/) {
                @data[$1].join("\n")
            }}.join("\n")
        end

        def say(a)
            puts _arr(a)
        end

        def _arr(a)
            unless Array === @data[a]
                @data[a] = []
            else
                @data[a]
            end
        end

      
        def poppush((a, b))
            _arr(b).push(_arr(a).pop)
        end

        def popunshift((a, b))
            _arr(b).unshift(_arr(a).pop)
        end

        def shiftpush((a, b))
            _arr(b).push(_arr(a).shift)
        end

        def shiftunshift((a, b))
            _arr(b).unshift(_arr(a).shift)
        end

        def clear((a))
            _arr(a).clear
        end

        def unshift((a, *b))
            _arr(a).replace(b.concat(_arr(a)))
        end
        
        def push((a, *b))
            _arr(a).concat(b)
        end

        def pop((a))
            _arr(a).pop
        end

        def shift((a))
            _arr(a).shift
        end

        def set((a, *b))
            _arr(a).replace(b)
        end

        def copy((a, b))
            _arr(b).replace(_arr(a))
        end

        def difflength((a, b, c))
            _arr(c).replace(_arr(b)[_arr(a).length..._arr(b).length]) 
        end


        def dup((a))
            _arr(a).push(_arr(a)[-1])
        end

        def dupn((a, b))
            _arr(a).push(_arr(a)[~b])
        end



        def writefile((a, *b))
             open(a, "w") do |f|
                b.each{|x|
                    f.write x
                    f.write "\n"
                }
            end
        end

        def readfile((a, b)) 
            _arr(b).replace(File.read(a).split("\n"))
        end

        def appendfile((a, *b))
            open(a, "a") do |f|
                b.each{|x|
                    f.write x
                    f.write "\n"
                }
            end
        end

        def exit_program
            exit
        end

        def exec(a)
            raise unless system a.join(" ")
        end

        def ws
            @data
        end

        def mixin((a, b))
            require a
            include Repl.const_get(b)
        end

        def _runlines(arr)
            current = nil
            arr.each{|x|
                current = x
                sym = x.keys[0]
                args = x.values[0]
                send sym, args
            }
        rescue
            puts "Error when executing #{YAML.dump(current)}"
            puts $!.to_s
            system "pause"
        end

        def run((a))
            key = _arr("STATE")[-1]
            _runlines ws[key]
            @data["STATE"].pop
        end

    
        def input(a)
            @regs ||= {}
            line = Readline.readline(_arr("INPUT_PROMPT").last, true)
            set ["INPUT", line]
            push ["MATCH", line]
        end

        def match((a))
            line = pop(["MATCH"]).to_s
            a.each{|k, v|
                next unless Symbol === k
                reg = (@regs[k] ||= Regexp.new(k.to_s))
                if reg =~ line
                    set ["MATCHARGS", *Regexp.last_match.to_a.reverse]
                    _runlines v
                    break
                end
            }
        end
    end

    def run(key = :MAIN)
        loop do
            r = Runner.new(@data[@current])
            r.run []
        end
    end
end

sep = ARGV.index('--')
if !sep
    fn = ARGV[0]
else
    fargs = ARGV[0, sep]
    largs = ARGV[(sep + 1)..-1]
    fn = fargs[0]    
end
    
text = fn ? File.read(fn) : DATA.read

r = Resource.new(text, largs, fn)
at_exit {
    r.dump(fn)
}
r.run

__END__
WS: default
HISTORY: []
FILENAME: []
default:
    CODE: 
       - |
          $<GLOBAL>
          int main() {
              $<TEXT>
          }

    SOURCE:   []
    GLOBAL:   ['#include <stdio.h>']
    TEXT:     []
    COMPLETE: []
    OUTPUT:   []
    HISTORY:  []
    STATE: 
       - :MAIN
    INPUT_PROMPT:
       - "~> "
    :MAIN:
       - push: 
         - STATE
         - :MAIN

       - input: []
       - match:
          :^test (\d+) (\d+):  
             - clear: T
             - dupn: [MATCHARGS, 2]
             - poppush: [MATCHARGS, T]
             - dupn: [MATCHARGS, 1]
             - poppush: [MATCHARGS, T]
             - say: T
          :^\+(.+):
             - dupn: [MATCHARGS, 1]
             - poppush: [MATCHARGS, SOURCE]
          :^#(.+):
             - dupn: [MATCHARGS, 1]
             - poppush: [MATCHARGS, GLOBAL]
          :.+:
             - poppush: [INPUT, TEXT]
             - push: 
                 - STATE
                 - :RUN
             - run: []
                 
             

    :RUN:
       - expand:     [CODE, app.c]
       - expand:     [SOURCE, run]
       - appendfile: [run, -o, app.exe, app.c]
       - exec:       [gcc, '@run']
       - exec:       [app.exe, "> output.txt"]
       - readfile:   [output.txt, T]
       - difflength: [OUTPUT, T, U]
       - say:        U
       - copy:       [U, OUTPUT]
       

 
