require 'readline'
require 'irb'
require 'yaml'

class Resource
    def initialize(text)
        @data = YAML.load text
        @current = @data["WS"]
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
            line = Readline.readline(a["prompt"], true)
            a.each{|k, v|
                next unless Symbol === k
                reg = (@regs[k] ||= Regexp.new(k.to_s))
                if reg =~ line
                    set ["INPUT", line]
                    set ["INPUTARGS", *Regexp.last_match.to_a.reverse]
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

text = DATA.read
r = Resource.new(text)
r.run

__END__
WS: default
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
    STATE: 
       - :MAIN
    :MAIN:
       - push: 
         - STATE
         - :MAIN

       - input:
          prompt: " >"
          :^test (\d+) (\d+):  
             - clear: T
             - dupn: [INPUTARGS, 2]
             - poppush: [INPUTARGS, T]
             - dupn: [INPUTARGS, 1]
             - poppush: [INPUTARGS, T]
             - say: T
          :^\+(.+):
             - dupn: [INPUTARGS, 1]
             - poppush: [INPUTARGS, SOURCE]
          :#(.+):
             - dupn: [INPUTARGS, 1]
             - poppush: [INPUTARGS, GLOBAL]
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
       - say: U
       - copy:       [U, OUTPUT]
       

 
