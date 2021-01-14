#require "readline"         #its better to use the rlwrap readline wrapper 
                            #from the shell: #rlwrap ./tree 
require "./quoted.cr"       #handling chars in quotes
require "./kws.cr"          #keywords proc hash table
require "./tree_help.cr"    #help function
require "./tree_math.cr"    #simple int math

VARS = {
  "started"  => true,       #used in prompt()
  "debug"    => false,      #toggle debug message output by entering debug
  "singlestep" => false,    #toggle singlestepping for functions
  "filename" => "",         #currrent file loaded
  "lines"    => 0,          #number of lines 
  "interactive" => true,    #more output in interaktive mode than in run mode
                            #but we do not write to stdout in an asignment e.g. a=now()
}

STACK = [] of String        #line result stack
OP = {"eq","=","/","*","+","-"}     #supported operators, first op has highest prio
CONTEXTS = [] of String     #contexts like "in_while","in_if" are added at runtime

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
      if VARS["interactive"] = false
        print "in File: #{VARS["filename"]} Line: #{Code.current_line}\n"
      end
    end  
      ex.backtrace.each { |line|
        puts line
      }
      Code.current_line = 0
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
    KWS.each { |d|
     #puts d     #  {"run", #<Proc(String, Int32, Int32):0x55a87122fcf0>}
     print "," if !startflag
     functions_filtered d
     startflag = false 
     }
     print "\n"
  end  
end

def functions_filtered(d)
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

#eval()=
#eval (interactive mode) a line by
#search for operators and 
#looking up the commands in the keyword hash
def eval(line)
  print "eval(): ",line,"\n" if VARS["debug"]
  word = ""
  if line && line != ""
    ary = full_split(line)   # needs full split which is a bit slower
    return if ary.size == 0  # check needed for lines with blanks

    OP.each { |op|            # check for operators in line(ary)
      if ary.includes?(op)    
        word = op             # define trigger word for proc table
        next
      end
    }  

    word = ary.shift if word.size==0 # get first word
    rol = ary.join(" ")              # rest of line

    print "Word: ",word,"\n" if VARS["debug"]
    print "Rol: ",rol,"\n" if VARS["debug"]

    if KWS.has_key?(word)
      KWS[word].call(rol, ary.size) #lookup and call functions
    else 
      puts check_if_var(word)       #print value to stdout
    end
  end
end

#eval (scripting mode) a line by
#search for operators and 
#looking up the commands in the keyword hash
def eval2(line)
    word = ""
    ary = line.split(" ") # here simple split is used which is faster

    OP.each { |op|            # check for operators in ary 
    if ary.includes?(op)    
      word = op
      next
    end
  }  

    word = ary.shift if word.size==0    # get first word
    rol = ary.join(" ")                 # rest of line

    if VARS["debug"]
      print "eval2(): ",line,"\n" 
      print "Word: ",word,"\n" 
      print "Rol: ",rol,"\n"
    end   

    if KWS.has_key?(word)
      KWS[word].call(rol, ary.size)
    else
      #res = lookup_vars(word)  # not in scrpting mode
      print "Function or var: ",'"',"#{word}",'"'," not found\n"
    end
end

def check_equal(line : String)
    pos = line.index("==")
    pos = line.index("= =") if !pos
    if pos
     res = !inside_quotes?('"',line,pos)
    else
     res = false
    end 
    #p! line,pos,res if VARS["debug"]
    return res  
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

#full_split()=
#is only run once per line eval or a fresh loadad file !
#split line into words by blank
#seperate operators from var names
#returns an array of strings  ["a","=","1"]
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

  #pre - split operators 
  to_split = "<>=+-/*"
  to_split.each_char { |char|
    line = split_operator_from_var(line,char)
  }
  ind = line.index("=  =") 
    if ind
     flag = inside_quotes?('"',line,ind)
     if !flag   
        line=line.gsub("=  =","eq")
     end
    end      

  line.split(" ", remove_empty: true) { |string|
    break if string[0] == '#'     # remove comments
    ary << string                 # "a+=1" ->  ["a", "+", "=", "1"]
  }
  puts "Line splitted: ", ary if VARS["debug"]
  return ary
end

#code()=
#load,run,list code
#loop fuction: while, end 
module Code
  @@codelines = [] of String
  class_property lines = 0
  class_property current_line = 0
  @@last_line = 0
  class_property vars_int32 = { } of String => Int32 
  class_property vars_string = { } of String => String
  @@jmp_trigger = -1
  @@start_line = -1
  @@skip_lines = false
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
    VARS["interactive"] = false
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
    @@jmp_trigger = -1
    @@start_line = -1

    size = @@codelines.size
    while line = @@codelines[@@current_line] 
      print "Current line: ",@@current_line+1," has ",line.size," chars\n" if VARS["debug"]
      if !@@skip_lines
        print '"',line,'"',"\n" if VARS["debug"]
        eval2(line)
      else
        # print "find end of block\n"
        if line.includes?("end")
          print "end found: ","in line: ",@@current_line+1,"\n" if VARS["debug"]
          @@skip_lines = false
        end  
      end
      if @@jmp_trigger != -1 # we got a number !?
        @@current_line = @@jmp_trigger.to_i 
        @@jmp_trigger = -1 # reset trigger
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
    VARS["interactive"] = true
  end # of run code
  
  #split_run()=
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
  
  #while()=
  #implement while
  def _while_(x : String, y : Int32)
    # while a < 77
    p! x,y if VARS["debug"]
    @@start_line = @@current_line
    CONTEXTS.push("in_while") if !CONTEXTS.index("in_while")

    if y == 3
      varname, cmp , value = x.split(" ")
      
       if cmp == "<" #check operator
        #result = _lower_("#{varname} #{cmp} #{value}", 3)
         if (@@vars_int32[varname] < value.to_i)
           result = 1
         else
           result = 0
         end  
       elsif
        cmp == ">"
        #result = _higher_("#{varname} #{cmp} #{value}", 3)
         if (@@vars_int32[varname] < value.to_i)
           result = 1
         else
           result = 0
         end  
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

      if result == 0 # loop conditions for while not met   
        @@skip_lines = true
        @@start_line = -1
        if VARS["debug"]
          print "set skip lines: true","\n" if VARS["debug"] 
          p! CONTEXTS
        end  
        #CONTEXTS.pop
        return
      end
  end

  #end()=
  #implement end
  def _end_
    context = CONTEXTS.last?
    @@jmp_trigger = @@start_line  # while blocks set a start line
    if VARS["debug"]   
      p! CONTEXTS
      print "set jmp trigger: ",@@start_line+1,"\n" 
    end  
  end

  #if()=""
  #implement if
  def _if_(x : String, y : Int32)
    # if a      #  if true returns 1      # if a var has a Int value > 0 it is true
                                          # if a var has a string value with size > 0 it is true 
                #  if false returns 0     
                #  if var <a> does not exist returns error "Nil assertion failed", script is stopped

    p! x,y if VARS["debug"]
    CONTEXTS.push("in_if") if !CONTEXTS.index("in_if")

    if y == 3  # "if a < 2"
      varname, cmp , value = x.split(" ")
       if cmp == "<" #check operator
        #result = _lower_("#{varname} #{cmp} #{value}", 3)
         if (@@vars_int32[varname] < value.to_i)
           result = 1
         else
           result = 0
         end  
       elsif
        cmp == ">"
        #result = _higher_("#{varname} #{cmp} #{value}", 3)
         if (@@vars_int32[varname] > value.to_i)
           result = 1
         else
           result = 0
         end  
       else
        result = 0
       end 
     end  


    # lets start with numeric comparison 
    if y == 4   # "if a eq 1" - equal operator
      _if_, varname, cmp, value = x.split(" ")
      #p!  _if_, varname, cmp, value
      if @@vars_int32[varname] == value.to_i   # equal ???
        result = 1
      else
        result = 0
      end
      print "result of if: ",result,"\n" if VARS["debug"]
    end



     # if true
     if y == 1   # if a - single token !
        cmp = x.split(" ")[0]
           
        res=false

        if cmp   # double nil check
          value=cmp.to_i?
          if value 
            res = true if value > 0
          end    
        end

        if @@vars_int32.has_key?(cmp)
          value = @@vars_int32[cmp]
          res = true if value > 0
        elsif @@vars_string.has_key?(cmp.gsub('"',""))
          value = @@vars_string[cmp]
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

        print "result of if(): ",result,"\n" if VARS["debug"]   
      end

      if result == 0 # if condition not met
        print "set skip lines: true","\n" if VARS["debug"]    
        @@skip_lines = true
        return
      end
  end
  #end of if
 

# lower "<" operator
def _lower_(x : String, y : Int32)
  # counter < 10
  p! "lower()",x,y if VARS["debug"]
  varname, operand, val = x.split(" ")
  value = val.to_i
  if @@vars_int32[varname] < value
    return 1
  else
    return 0
  end
end

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

#let()=
#set var to result of function 
#set var to a value
#or set var to other var
#no operators like +-* supported on right side of = for now
# <myintvar> = 7
# <mystringvar> = "some test"
# a = b
def let(x : String,y : Int32)
  p! "let()",x,y if VARS["debug"]
   varname = x.split(" ")[0]  # number on left side
   if varname.to_i?
      print "numbers can't be var names\n"
      return
   end    
   value = (x.split(" ")[3..].join(" ")) # rest of line
   word = x.split(" ")[2]
   
   istate = VARS["interactive"] 
   VARS["interactive"] = false   #we dont want to see output of typeof
   t,v = _typeof_(word,1) #is it a proc ?
   VARS["interactive"] = istate

   
   if t == "proc"
    if KWS.try &.has_key?(word)
      y1 = y - 3 # we cant use y here, because it is already used !!!
                 # we call a proc inside a proc and share the same set of vars !!! 
      istate = VARS["interactive"] 
      VARS["interactive"] = false    
      KWS.not_nil![word].call(value, y1) #lookup and call functions
      VARS["interactive"] = istate
    #check result of call
    s = word + ".result" # function result string
    if Code.vars_string.has_key?(s)
      res = Code.vars_string[s]
      Code.vars_string[varname] = res
      return
    else 
      return
    end   
   end
  end 
      
   value = (x.split(" ")[2..].join(" ")) # rest of line
   #flag1 = inside_quotes?('"',value,0) || inside_quotes?("'",value,0) # works but it can be faster
   if (value[0] == '"' && value[-1] == '"')  # its a quoted string
      flag1 = true
   else
    flag1 = false
   end  
   if !(flag1 || value.to_i?)      # if its inside quotes or an int it is for sure no var
      value = check_if_var(value)     # lets see it the var really exists and get its value
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

#check_if_var()=
#check if a var with that name exists
#and return the value
def check_if_var(x : String)
 if x.to_i?    #just a number ?
    return x 
 end   

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
 fn = "check_if_var"
 print fn + "():\n" if VARS["debug"]
 print "var: " + '"' + x + '"' + " not found\n"
 return "nil"  # return error if var not found
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

#_p_()=
#print var value to stdout
#var value is stored in var: p.result 
def _p_(x : String)
  value = check_if_var(x)
  let("p.result = #{value}",3)
  puts value 
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

#method_err(name,input string)
def method_err(fn,x)
  print "Method #{fn}\(\) failed, please check arguments\n"
  print "got: ", x,"\n"
end

#typeof()=
def _typeof_(x : String, y : Int32)
  print "typeof() got: ",x,"\n"  if VARS["debug"]
  res,v = "",0
  return res,v if y != 1   # check number of args
  if (x[0] == '"' && x[-1] == '"')   # a (quoted) string
    res = "string"; v=1
  elsif x.to_i?; 
    res = "int32"; v=2
  elsif KWS.has_key?(x)
    res = "proc" ; v=3
  elsif Code.vars_string.has_key?(x)
    res = "var-string"; v=4
  elsif Code.vars_int32.has_key?(x)
    res = "var-int32"; v=5
  else 
    res = "unknown type"; v=-1
  end
  if VARS["interactive"]
    puts res
  end
  Code.vars_string = Code.vars_string.merge({"typeof.result" => res}) 
  return res,v 
end  

def _puts_(x : String)
 x=unquote(x)
 puts x
 return "",0
end  

