#require "readline"         #its better to use the rlwrap readline wrapper 
                            #from the shell: #rlwrap ./tree 
require "./quoted.cr"
VARS = {
  "started"  => true,       #used in prompt()
  "debug"    => false,      #toggle debug message output by entering debug
  "singlestep" => false,    #toggle singlestepping for functions
  "filename" => "",         #currrent file loaded
  "lines"    => 0,          #number of lines 
}

CONTEXTS = [] of String     #block contexts like "in_while","in_if" are added at runtime

KEYWORDS = [ # list grows during runtime, when procs are added
  {"print", ->(x : String, y : Int32) { puts x; return 0 }},
  {"load", ->(x : String, y : Int32) { Code.load x; return 0 }},
  {"eval", ->(x : String, y : Int32) { eval x; return 0 }},
  {"ceval", ->(x : String, y : Int32) { ceval x; return 0 }},
  {"after", ->(x : String, y : Int32) { _after_(x, y); return 0 }},
  {"+", ->(x : String, y : Int32) { plus(x, y) }},
  {"-", ->(x : String, y : Int32) { minus(x, y) }},
  {"inc", ->(x : String, y : Int32) { inc(x, y) }},
  {"dec", ->(x : String, y : Int32) { dec(x, y) }},
  {"<", ->(x : String, y : Int32) { _lower_(x, y) }},
  {">", ->(x : String, y : Int32) { _higher_(x, y) }},
  {"if", ->(x : String, y : Int32) { Code._if_(x, y); return 0 }},
  {"while", ->(x : String, y : Int32) { Code._while_(x, y); return 0 }},
  {"every", ->(x : String, y : Int32) { t = Timer.new; t.timer_test(x,y); return 0 }},
  {"ls", ->(x : String, y : Int32) { ls(x,y); return 0 }},
  {"let", ->(x : String, y : Int32) { let(x,y); return 0 }},
  {"delete", ->(x : String, y : Int32) { delete x; return 0 }},
  {"clear", ->(x : String, y : Int32) { clear x; return 0 }},
  {"p", ->(x : String, y : Int32) { _p_ x; return 0 }},
  {"!", ->(x : String, y : Int32) { system(x); return 0 }},
  {"now", ->(x : String, y : Int32) { puts Time.local.to_s("%H:%M:%S.%6N"); return 0 }},
  {"help", ->(x : String, y : Int32) { help(x); return 0 }},
  {"debug", ->(x : String, y : Int32) { VARS["debug"] = !VARS["debug"]; puts "debug is now: ", VARS["debug"]; return 0 }},
  {"singlestep", ->(x : String, y : Int32) { VARS["singlestep"] = !VARS["singlestep"]; puts "singlestep is now: ", VARS["singlestep"]; return 0 }},
  {"test", ->(x : String, y : Int32) { procloop; return 0 }},
  {"sleep",->(x : String, y : Int32) { sleep(x.to_i); return 0 }},
  {"pass", ->(x : String, y : Int32) { pass; return 0 }},
  {"end", ->(x : String, y : Int32) { Code._end_; return 0 }},
  {"cls", ->(x : String, y : Int32) { print "\33c\e[3J"; return 0 }},
  {"exit", ->(x : String, y : Int32) { exit(0) }},
]

#register Code evaluater functions and procs
Code.register
if ARGV.size == 1        # run file non interactive
  file = ARGV[0]         # get the filename
  eval("load #{file}")
  eval2("run")
  exit
end

repl()

#run interactive if no file given or file not found
#error handler: print out error message and backtrace 
def repl
  line = ""
  loop do
    prompt()
    line = read_command()
    eval(line)
  rescue ex
    print "Error in: #{line}\n", ex.message, "\n"
    if Code.current_line > 0
      print "in File: #{VARS["filename"]} Line: #{Code.current_line}\n"
      ex.backtrace.each { |line|
        puts line
      }
      Code.current_line = 0
    end
  end
end

def prompt
  puts "Welcome to tree" if VARS["started"]
  VARS["started"] = false
  print ">"
end

#ls()=
#list VARS and/or functions
def ls ( x : String, y : Int32)
  p! x,y if VARS["debug"]
  if y > 1 
     puts "Method ls needs 0 or 1 argument"
     puts "got: ", x
     return
  end   
  if ((y == 1 && x == "vars") || (y == 0))
    print "builtin vars: "
    puts VARS # builtin constants can change their value
    print "user vars: \n"
    print "vars_int32: ",Code.vars_int32,"\n" if Code.vars_int32.size > 0
    print "vars_string: ",Code.vars_string,"\n" if Code.vars_string.size > 0  
    print "contexts: ",CONTEXTS,"\n" if CONTEXTS.size > 0
  end
  if ((y == 1 && x == "functions") || (y == 0))
    print "functions: "
    startflag=true
    Code.kwh.each { |d|
     #puts d     #  {"run", #<Proc(String, Int32, Int32):0x55a87122fcf0>}
     print "," if !startflag
     puts_filtered d
     startflag = false 
     }
     print "\n"
  end  
end


def puts_filtered(d)
 pd = d.inspect
 eindex = pd.index('"',2) # search for closing quote
 if eindex
  res = pd[2,eindex-2]
  print res
 end  
 return
end


#read line from STDIN
def read_command
  #line = Readline.readline(prompt = ">", add_history = true)
  line = STDIN.gets
end

def help(*arg)  
helptext = <<-HELP
List vars, functions: 
>ls # list all
>ls vars
>ls functions

Set,clear,delete vars:
>counter = 5 
>name = foo
>counter+ = 2
>clear           #clear all user vars
>delete varname  #delete a user var

Print Strings, vars:
>p <varname> 
>print hello    

Call functions:
>now            # display current time
>after 5 exit   # call exit in 5 seconds
>every 5 now    # Set timers to run <function> every 5 seconds
                # here we just print the time
                # stop all started timers by typing >stop = 1

Load,run,list a script:
>load <filename>
>run  
>list
Run a script from cli:
./tree <filename>

Execute shell commands by ! prefix:
>!pwd      
>!icr     #use icr(interactive crystal), exit with ^D
           #https://github.com/crystal-community/icr

Toggle debug on/off:
>debug

Execute functions like they were typed in:
>eval help

Eval via the crystal binary:
Expression is compiled and then executed.
This will take about a second per evaluation. 
>ceval 1+2
>ceval puts "aha"
The result is stored as a string in the user var:
ceval.result

HELP

puts helptext

if VARS["debug"]
    p! arg
    p! arg.first?
  end
end

#eval (interactive mode) a line by
#search for operators and 
#looking up the commands in the keyword hash
def eval(line)
  print "eval: ",line,"\n" if VARS["debug"]
  word = ""
  if line && line != ""
    ary = [] of String
    ary = full_split(line)   # needs full split which is a bit slower
    return if ary.size == 0  # check needed for lines with blanks
    unshifted = false
    if ary.includes?("+") # found operator in command ?
      ary.unshift("+")
      unshifted = true
    end
    if ary.includes?("-") # found operator in command ?
      ary.unshift("-")
      unshifted = true
    end
    #when all operators done we do assignment
    if !unshifted && ary.includes?("=") # found = operator in command ?
        ary.unshift("let")              # do assignment when operators done 
    end
    word = ary.shift                 # get first word
    return if word.starts_with?("#") # skip comments
    rol = ary.join(" ")              # rest of line

    print "Word: ",word,"\n" if VARS["debug"]
    print "Rol: ",rol,"\n" if VARS["debug"]

    if Code.kwh.try &.has_key?(word)
      Code.kwh.not_nil![word].call(rol, ary.size) #lookup functions
    else 
      res = lookup_vars(word)
      print "Function or var: ",'"',"#{word}",'"'," not found\n" if !res
    end
  end
end

def lookup_vars(word)
 ret = false
 if Code.vars_int32.has_key?(word)
  puts Code.vars_int32[word]
  ret = true
 end
 if Code.vars_string.has_key?(word)
  puts Code.vars_string[word]
  ret = true 
 end
 return ret
end

#eval (scripting mode) a line by
#search for operators and 
#looking up the commands in the keyword hash
def eval2(line)
  print "eval: ",line,"\n" if VARS["debug"]
  word = ""
  if line && line != ""
    ary = [] of String
    ary = line.split(" ") # here simple split is used which is faster
    unshifted = false
    if ary.includes?("+") # found operator in command ?
      ary.unshift("+")
      unshifted = true
    end
    if ary.includes?("-") # found operator in command ?
      ary.unshift("-")
      unshifted = true
    end
    if !unshifted && ary.includes?("=") # found operator in command ?
        ary.unshift("let")
    end
    word = ary.shift                 # get first word
    return if word.starts_with?("#") # skip comments
    rol = ary.join(" ")              # rest of line

    print "Word: ",word,"\n" if VARS["debug"]
    print "Rol: ",rol,"\n" if VARS["debug"]

    if Code.kwh.try &.has_key?(word)
      Code.kwh.not_nil![word].call(rol, ary.size)
    else
      res = lookup_vars(word)
      print "Function or var: ",'"',"#{word}",'"'," not found\n" if !res
    end
  end
end


#eval a line by  
#passing the line to the crystal binary 
def ceval(line)
  #print "eval: ",line,"\n" if VARS["debug"]
  if line && line != ""
    line = "puts " + line
    cmd  = "crystal"
    args = ["eval", line]
    status, output = run_cmd(cmd, args)
    puts output  
    # ser user var
    Code.vars_string = Code.vars_string.merge({"ceval.result" => output.chomp})  
    else
      puts "Line is empty"
   end
end

#run cmd as a subprocess and capture the output
def run_cmd(cmd, args)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(cmd, args: args, output: stdout, error: stderr)
  if status.success?
    {status.exit_code, stdout.to_s}
  else
    {status.exit_code, stderr.to_s}
  end
end

#split line into words by blank
#seperate operators from var names
def full_split(line)
  puts "Line in: ", line if VARS["debug"]
  ary = [] of String
  # execute shell command
  if line.starts_with?("!")
   return ["!",line.lchop]  
  end  

  if line.starts_with?("ceval ")
    return ["ceval",line.lchop("ceval ")]
  end

  #pre - split operators - is only run once on per line eval or a loadad file !
  to_split = "<>=+-"
  to_split.each_char { |char|
    line = split_operator_from_var(line,char)
  }
 
  line.split(" ", remove_empty: true) { |string|
    ary << string                 # "a+=1" ->  ["a", "+", "=", "1"]
  }
  puts "Line splitted: ", ary if VARS["debug"]
  return ary
end

#code()=
#load,run,list code
#loop fuction: while, end 
#register and merge procs
#into a central hash 
#named kwh - Keyword hash  
module Code
  class_property kwh = Hash(String, Proc(String, Int32, Int32)).new
  class_property codelines = [] of String
  class_property lines = 0
  class_property current_line = 0
  class_property last_line = 0
  class_property vars_int32 = { } of String => Int32 
  class_property vars_string = { } of String => String
  class_property jmp_trigger = "no"
  class_property start_line = "no"
  class_property in_while = false
  class_property skip_lines = false
  extend self
  
  #load code into the
  #String array  
  def load(filename)
    if File.exists?(filename)
      fd = File.open(filename)
      @@codelines.clear
      @@lines = 0
      while line = fd.gets
        # puts line
        @@codelines << line
        @@lines += 1
      end
      fd.close
      VARS["filename"] = filename
      VARS["lines"] = lines
      print "Loaded: ", filename, " Number of lines: ", lines, "\n"
      @@last_line=@@codelines.size
      split_run
    else
      puts "File #{filename} not found"
    end
  end

  #run()=
  #run code
  #run s # single step mode on
  def run(arg)
    return if VARS["filename"] == ""
    if arg == "s" 
      puts "press return - execute a single line"
      puts "press q to stop the program"
      puts "press c to continue run"
      VARS["singlestep"] = true
    else
      VARS["singlestep"] = false
    end    
    
    @@current_line = 0
    @@skip_lines = false
    @@jmp_trigger = "no"
    @@start_line = "no"

    size = @@codelines.size
    while line = @@codelines[@@current_line] 
      print "Current line: ",@@current_line+1," has ",line.size," chars\n" if VARS["debug"]
      if !@@skip_lines
        print '"',line,'"',"\n" if VARS["debug"]
        eval2(line)
      else
        # print "find end of block\n"
        @@skip_lines = false if line.includes?("end")
      end
      if @@jmp_trigger != "no"
        @@current_line = @@jmp_trigger.to_i 
        @@jmp_trigger = "no" # reset trigger
        print "Jumping to: ",@@current_line+1," ",@@codelines[@@current_line],"\n" if VARS["debug"]
      else
        @@current_line += 1
        if VARS["singlestep"]    # wait for return key
          sread = STDIN.gets() 
          eval(sread) if (sread && sread.size > 1)
           if sread == "c"        # keys for single step mode
             print "continue\n"
             VARS["singlestep"] = false
           end        
           if sread == "q"
            print "stop\n"
            VARS["singlestep"] = false
           return
           end
        end   
      end
      break if @@current_line >= @@last_line
    end # of loop
    print "reached end of file in line: ",@@current_line,"\n"
    @@current_line=0
  end # of run code
  
  #split codelines into tokens
  #seperate operaters from var names by blank
  #remove comment lines
  def split_run()
    return if VARS["filename"] == ""
    @@current_line = 0
    @@last_line=0
    delflag=false
    while line = @@codelines[@@current_line] 
      print "Current line:",@@current_line+1,"\n" if VARS["debug"]
      print "Split line: ", line," ",line.size, "\n" if VARS["debug"]
      ary = [] of String
      if (!(line.starts_with?("#") || full_split(line).size == 0 ))  # skip comment lines and empty lines
        ary = full_split(line)
        @@codelines[@@current_line] = ary.join(" ")  # write line back to codelines 
      else
        @@codelines.delete_at(@@current_line) # remove line from code
        delflag=true
      end  
      if !delflag
        @@current_line += 1
      else
        delflag=false
      end     
      @@last_line=@@current_line
      break if @@current_line >= @@codelines.size
    end # of loop
    puts "code cleanup done in split_run()"
    print "Current number of lines: ",@@current_line,"\n"
  end # of split code

  #list()=
  #list the code
  def list
    @@current_line=0
    while @@current_line < @@last_line 
      puts @@codelines[@@current_line] 
      @@current_line += 1
    end  
  end

  #merge the keyword hash 
  def kws
    kws = {
      "run"  => ->(x : String, y : Int32) { run x; return 0 },
      "split_run"  => ->(x : String, y : Int32) { split_run; return 0 },
      "list" => ->(x : String, y : Int32) { list; return 0 },
    }
    index = 0
    while (index < KEYWORDS.size)
      kw = KEYWORDS.[index][0]
      proc = KEYWORDS.[index][1]
      # print kw ," ", KEYWORDS.[index][1],"\n"
      kws = kws.merge({kw => proc})
      index += 1
      # print kws[ "#{ kw }" ],"\n"
    end
    return kws
  end

  #register functions 
  def register
    @@kwh = Code.kws
  end
  
  #while()=
  #implement while
  def _while_(x : String, y : Int32)
    # while a < 77
    p! x,y if VARS["debug"]
    @@start_line = @@current_line.to_s
    CONTEXTS.push("in_while") if !CONTEXTS.index("in_while")

    if y == 3
      varname, cmp , value = x.split(" ")
      
       if cmp == "<" #check operator
        result = _lower_("#{varname} #{cmp} #{value}", 3)
       elsif
        cmp == ">"
        result = _higher_("#{varname} #{cmp} #{value}", 3)
       else
        result = 0
       end 
     end  
     # while true
     if y == 1
        cmp = x.split(" ")[0]
        if cmp == "true" #check operator
          result = 1
        else 
          result = 0
        end
      end

      if result == 0 # loop conditions not met
        print "set skip lines: true","\n" if VARS["debug"]    
        @@skip_lines = true
        p! CONTEXTS if VARS["debug"]
        CONTEXTS.pop
        return
      end
  end

  #end()=
  #implement end
  def _end_
    p! CONTEXTS if VARS["debug"]
    context = CONTEXTS.last?
    @@jmp_trigger = @@start_line if (context == "in_while")
    CONTEXTS.pop if context == "in_if"
    print "set jmp trigger: ",@@start_line.to_i+1,"\n" if VARS["debug"]  # this is for while
  end

  #if()=""
  #implement if
  def _if_(x : String, y : Int32)
    # if a      #  if true returns 1      # if a var has a Int value > 0 it is true
                                          # if a var has a string value with size > 0 it is true 
                #  if false returns 0     
                #  if var <a> does not exist returns error "Nil assertion failed", script is stopped

    p! x,y if VARS["debug"]
    CONTEXTS.push("in_if")

    if y == 3
      varname, cmp , value = x.split(" ")
       if cmp == "<" #check operator
        result = _lower_("#{varname} #{cmp} #{value}", 3)
       elsif
        cmp == ">"
        result = _higher_("#{varname} #{cmp} #{value}", 3)
       else
        result = 0
       end 
     end  
     # if true
     if y == 1   # if a - single token !
        cmp = x.split(" ")[0]
           
        res=false

        if cmp
          value=cmp.to_i?
          if value 
            res = true if value > 0
          end    
        end

        if Code.vars_int32.has_key?(cmp)
          value = Code.vars_int32[cmp]
          res = true if value > 0
        elsif Code.vars_string.has_key?(cmp.gsub('"',""))
          value = Code.vars_string[cmp]
          res = true if value.size >= 1  # string length
          else
          res = true if cmp.size > 2 # a string on its own is true when longer ""
          res = false if cmp == "false"
        end   
 
        if res == true #check int,string value or var with value
          result = 1
        else
          result = 0
        end

        print "result of if: ",result,"\n" if VARS["debug"]   
      end

      if result == 0 # if condition not met
        print "set skip lines: true","\n" if VARS["debug"]    
        @@skip_lines = true
        return
      end
  end
  #end of if
end   
#end of Code module


class Timer
  property name ="Test Name"

  def initialize
    puts "New instance started"
    p! self.name
    p! self.object_id
  end  

def timer_test(x , y)
if y >=2
  interval = x.split(" ")[0]
  job = x.split(" ")[1..].join(" ") # get the rest of line
    puts "timer_test called with interval: #{interval}" 
    eval ("stop = 0")
    return if interval == ""
    eval ("interval = #{interval.to_i}")      #try to set a hash value
    if Code.vars_int32.has_key?("interval")   #check if the var really exists now
      puts "Var interval exists"
      puts "Message from Timer, type >stop = 1 to stop all started timers"
    end
    spawn {
      loop do
        eval job   
        sleep (Code.vars_int32["interval"])
        break if Code.vars_int32["stop"] == 1
      end
    }
 else
  puts "Method needs at least 2 arguments"
 end 
end 
end

#call function after x seconds
def _after_(x : String, y : Int32)  
print "function after called with: \n",x,y,"\n"  
  spawn do
    if y >= 2
      sleep S.shift(x, start = true).to_i
      rol = ""
      while y > 1
        rol += S.shift(x) + " "
        y -= 1
      end
      eval rol
    else
      puts "Method needs at least 2 arguments"
    end
  end
end

#S.shift gets elem from string
module S 
  class_property ind = 0
  
  def self.shift(x, start = false)
    if start
      @@ind = 0
    end
    ret = x.split(" ")[@@ind]
    @@ind += 1
    return ret
  end
end

def p_time
  puts(Time.local.to_s("%H:%M:%S.%6N"))
end

def procloop
  puts(Time.local.to_s("%H:%M:%S.%6N"))
  10.times {
    procs = {->pass}
    procs.each do |p|
      p.call
    end
  }
  puts(Time.local.to_s("%H:%M:%S.%6N"))
end

#do nothing
def pass
end

#set var to a value
#or set var to other var
#no operators like +-* supported on right side of = for now
# <myintvar> = 7
# <mystringvar> = "some test"
# a = b
def let(x : String,y : Int32)
  p! x,y if VARS["debug"]
  varname = x.split(" ")[0]
  if varname.to_i?
    print "numbers can't be varnames\n"
    return
  end    
  value = (x.split(" ")[2..].join(" ")) # rest of line
  flag1 = inside_quotes?('"',value,0) || inside_quotes?("'",value,0)
  if !(flag1 || value.to_i?)
     value = check_if_var(value)
  end   
  if value 
    if value.to_i? 
      Code.vars_int32 = Code.vars_int32.merge({varname => value.to_i})
      Code.vars_string.delete(varname)
    else if
      value=value.gsub('"',"")  # remove ""
      Code.vars_string = Code.vars_string.merge({varname => value})
      Code.vars_int32.delete(varname)
    end 
  end
end
end

#check if a var with that name exists
#and return the value
def check_if_var(x : String)
 if x.includes?(" ") #it is no valid varname, includes a blank
   return x 
 end
 
 if Code.vars_int32.has_key?(x)
  value = Code.vars_int32[x]
  return value.to_s
 end

 if Code.vars_string.has_key?(x)
  value = '"' + Code.vars_string[x] + '"'
  return value
 end
 fn ="check_if_var"
 #most of the time check_if_var should be silent
 #print fn + " ():" +" var " + '"' + x + '"' + " not found\n"
 return value  # return self if no key found

end

#clear all vars in the hashes
def clear(x : String)
  Code.vars_int32.clear
  Code.vars_string.clear
end

#delete a var in the hashes
def delete(x : String)
  varname = x.split(" ")[0]
  Code.vars_string.delete(varname)
  Code.vars_int32.delete(varname)
end

#print var value to stdout
#var value is stored in var: p.result 
def _p_(x : String)
  if Code.vars_int32.has_key?(x)
    result=Code.vars_int32[x].to_i
    p result
    let("p.result = #{result}",3)  
  else if Code.vars_string.has_key?(x)
    result = Code.vars_string[x]
    p result
    let("p.result = #{result}",3)
  else
    fn = "_p_"
    puts fn + "(): " + "var not found" 
  end
 end
end

# lower "<" operator
def _lower_(x : String, y : Int32)
  # counter < 10
  p! "lower()",x,y if VARS["debug"]
  varname, operand, val = x.split(" ")
  value = val.to_i
  if Code.vars_int32[varname] < value
    return 1
  else
    return 0
  end
end

# higher ">" operator
def _higher_(x : String, y : Int32)
  # counter > 10
  p! "higher()",x,y if VARS["debug"]
  varname, operand, val = x.split(" ")
  value = val.to_i
  if Code.vars_int32[varname] > value
    return 1
  else
    return 0
  end
end

# add value to a var
# example:  counter+= 3
# splitted: counter + = 3
# a = b + x works
def plus(x : String, y : Int32)
  p! "plus()",x,y if VARS["debug"]
  if y == 5 # countera = counterb + 1
     lside, rside = x.split(" = ",remove_empty: true)
     p! rside, lside if VARS["debug"]
     rside_s = rside.split(" ",remove_empty: true)
     #if "a = a + 1"
     rside_s.insert(2,"=")
     rside_j = (rside_s.join(" "))
     if lside == rside_s[0]
      x = rside_j # rewrite "counter = counter + 1" to "counter + = 1"
      y = 4
     else  # numeric int only !
      #rside_res = rside_s[0].to_i + rside_s[3].to_i
      rside_res = (value = check_if_var(rside_s[0])).not_nil!.to_i + rside_s[3].to_i
      Code.vars_int32[lside] = rside_res
      p! rside_res if VARS["debug"]
      return 0
     end
     p! rside_s,rside_j,rside_res if VARS["debug"]
     #return 0
  end 
  if y == 4
    varname = x.split(" ")[0]
    value = x.split(" ")[3].to_i
    Code.vars_int32[varname] += value
  else
    puts "Method plus needs at least 4 arguments"
    puts "got: ", x,y
  end
  return 0
end

# subtract value from a var
# example:  counter-= 3
# splitted: counter - = 3
def minus(x : String, y : Int32)
  p! x if VARS["debug"] 
  if y == 4
    varname = x.split(" ")[0]
    value = x.split(" ")[3].to_i
    Code.vars_int32[varname] -= value
  else
    puts "Method minus needs at least 4 arguments"
    puts "got: ", x
  end
  return 0
end


# increment var value 
def inc(x : String, y : Int32)
  if y == 1
    varname = x.split(" ")[0]
    Code.vars_int32[varname] += 1
  else
    puts "Method inc needs 1 argument"
    puts "got: ", x
  end
  return 0
end

# decrement var value 
def dec(x : String, y : Int32)
  if y == 1
    varname = x.split(" ")[0]
    Code.vars_int32[varname] -= 1
  else
    puts "Method dec needs 1 argument"
    puts "got: ", x
  end
  return 0
end
