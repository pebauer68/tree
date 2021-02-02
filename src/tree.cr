#require "readline"         #its better to use the rlwrap readline wrapper 
                            #from the shell: #rlwrap ./tree 
require "./quoted.cr"       #handling chars in quotes
require "./kws.cr"          #keywords proc hash table
require "./tree_help.cr"    #help function
require "./tree_math.cr"    #simple int math with 2 operands

VARS = {
  "started"  => true,       #used in prompt()
  "debug"    => false,      #toggle debug message output by entering debug
  "singlestep" => false,    #toggle singlestepping 
  "filename" => "",         #currrent file loaded
  "lines"    => 0,          #number of lines 
  "interactive" => true,    #more output in interaktive mode than in run mode
                            #but we do not write to stdout in an asignment e.g. a=now()
}

STACK = [] of Int32         #line number stack used in functions
CONTEXTS = ["in_function main"]     #contexts like "in_while","in_if" are added at runtime
ROL=[""]                    #rest of line as String - function call args
OP = {"eq","=","/","*","+","-"}     #supported operators, first op has highest prio
Code.add_fun("main","args",0)       #add a namespace for main
eval("trace=0") 
Code.cfu="main"                     #current function is main on startup

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
      if readvar("trace").to_i == 1
        ex.backtrace.each { |line|
          puts line
        }
      end   
      reset()
  end
end

def reset()
  Code.current_line = 0
  CONTEXTS.clear
  Code.cfu = "main"
  STACK.clear
  CONTEXTS.push("in_function main") 
  Code.skip_lines = false
  VARS["interactive"] = true
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
    print "current function: ",Code.cfu,"\n" 
  end
  if ((y == 1 && x == "functions") || (y == 0))
    print "procs: "
    startflag=true
    KWS.each { |d|
     #puts d     #  {"run", #<Proc(String, Int32, Int32):0x55a87122fcf0>}
     print "," if !startflag
     functions_filtered d
     startflag = false 
     }
     print "\n"
  end  
    print "functions: \n"
    Code.functions.each { |fun_name |
      puts fun_name
      }          
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
    Code.line = line
    ary = full_split(line)   # needs full split which is a bit slower
    return if ary.size == 0  # check needed for lines with blanks
    Code.rols = ary

    OP.each { |op|            # check for operators in line(ary)
      if ary.includes?(op)    
        word = op             # define trigger word for proc table
        next
      end
    }  

    word = ary.shift if word.size==0 # get first word
    rol = ary.join(" ")              # rest of line
    ROL[0] = rol

    print "Word: ",word,"\n" if VARS["debug"]
    print "Rol: ",rol,"\n" if VARS["debug"]

    if KWS.has_key?(word)
      sres,sval = KWS[word].call(rol, ary.size) #lookup and call proc functions
      puts sres if (sres != "nil" && sres.to_s.size > 0)
    else
      Code.current_line = Code.last_line # last_line gets pushed in case we call a function
      res = check_name(word)       #check for vars, functions
      puts res if res != word      #write var value or functions result to stdout
    end
  end
end

#eval2()=  (scripting mode) a line by
#search for operators and 
#looking up the commands in the keyword hash
def eval2(line)
    word = ""
    ary = line.split(" ") # here simple split is used which is faster
    Code.rols = ary

    OP.each { |op|            # check for operators in ary 
    if ary.includes?(op)    
      word = op
      next
    end
  }  

    word = ary.shift if word.size==0    # get first word
    rol = ary.join(" ")                 # rest of line
    ROL[0] = rol                        # as a string

    if VARS["debug"]
      print "eval2(): ",line,"\n" 
      print "Word: ",word,"\n" 
      print "Rol: ",rol,"\n"
    end   

    if KWS.has_key?(word)
      sres,sval = KWS[word].call(rol, ary.size)  #check for proc functions
      puts sres if (sres != "nil" && sres.to_s.size > 0)
    elsif
      res = check_name(word)       #check for vars, functions
      puts res if res != word      #write var value or functions result to stdout
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
  #handle assignment operator
  ind = line.index("=  =") 
    if ind
     flag = inside_quotes?('"',line,ind)
     if !flag   
        line=line.gsub("=  =","eq")
     end
    end 
      
  #insert blank before left parens "("
  #needed for functions e.g. foo (args)
        
  ind = line.index("(")
     if ind
      flag = inside_quotes?('"',line,ind)
       if !flag   
         line=line.gsub("("," (")
       end
    end   
    
  #replace blanks inside quotes 
  offset = 0
   while offset < line.size
      ind = line.index(" ",offset)
      if ind
       flag = inside_quotes?('"',line,ind)
       if flag   
         line = line.sub(ind,"") 
         #line = line.insert(ind,"\xc2\xa0")
         line = line.insert(ind,"_")
       end
    end   
    offset+=1
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
  class_property line = ""             #current line of code
  class_property rols = [] of String   #current line of code splitted in array
  class_property last_line = 0
  class_property vars_int32 = { } of String => Int32 
  class_property vars_string = { } of String => String
  class_property skip_lines = false
  class_property functions = { } of String => Hash(String,(String|Int32))  
  class_property cfu = "main"   # current function
  @@jmp_trigger = -1
  @@current_line = 0
  @@running = false
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
    end    
    
    @@running = true
    @@skip_lines = false
    CONTEXTS.push("in_function main") if CONTEXTS.size==0
    Code.cfu = "main"

    size = @@codelines.size
    while @@line = @@codelines[@@current_line] 
      print "Current line: ",@@current_line+1," has ",line.size," chars\n" if VARS["debug"]
      puts CONTEXTS if VARS["debug"]
      
      if !@@skip_lines
        print "evaluating: \"",@@line,'"',"\n" if VARS["debug"]
        eval2(@@line)
      elsif @@line.includes?("end") # skip these lines but take notice for context of blocks
          if VARS["debug"]
            print "end found: ","in line: ",@@current_line+1,"\n"
          end
          eval2(line)  # we need to evalute end
        elsif  # keep track of if/end context
          if @@line.includes?("if ")  
            CONTEXTS.push("in_if #{@@current_line+1}")
          end
          else
          puts "Skipping Line" if VARS["debug"]
            end

      if @@jmp_trigger != -1 # we got a valid line number !?
          @@current_line = @@jmp_trigger.to_i 
          @@jmp_trigger = -1 # reset trigger
          print "run(),Jumping to: ",@@current_line+1," ",@@codelines[@@current_line],"\n" if VARS["debug"]
      else
        @@current_line += 1
      end  
      
      if VARS["singlestep"]    # wait for any key
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

      break if @@current_line >= @@last_line
    end # of loop
    print "reached end of file in line: ",@@last_line,"\n" if VARS["debug"]
    @@running = false
    @@current_line=0
    CONTEXTS.clear
    VARS["interactive"] = true
    Code.cfu="main"
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
    @@current_line=0
  end # of split code

  #list()=
  #list the code
  def list
    @@current_line=0
    while @@current_line < @@last_line 
      print @@current_line+1,": ",@@codelines[@@current_line],"\n" 
      @@current_line += 1
    end  
  end
  
  #while()=
  #implement while
  def _while_(x : String, y : Int32)
    # while a < 77
    p! x,y if VARS["debug"]

    if y == 3
      varname, cmp , value = @@rols

       if cmp == "<" #check operator
        #result = _lower_("#{varname} #{cmp} #{value}", 3)
         #if (@@vars_int32[varname] < value.to_i)
         if (@@functions[Code.cfu][varname].to_i < value.to_i)
           puts "while < is true: ",@@functions[Code.cfu][varname].to_i if VARS ["debug"]
           result = 1
         else
           result = 0
         end  
       elsif
        cmp == ">"
        #result = _higher_("#{varname} #{cmp} #{value}", 3)
         if (@@functions[Code.cfu][varname].to_i > value.to_i)
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
        cmp = @@rols[0]
        if cmp == "true" #check operator
          result = 1
        else 
          result = 0
        end
      end
      
      CONTEXTS.pop if CONTEXTS.last.includes?("in_while #{@@current_line+1}")
      if result == 0 # loop conditions for while not met   
        @@skip_lines = true
        if VARS["debug"]
          print "set skip lines: true","\n" 
          p! CONTEXTS
        end 
        CONTEXTS.push("in_while #{@@current_line+1} skip") 
      else # loop conditions for while met
        CONTEXTS.push("in_while #{@@current_line+1}")
      end   
      return
  end

  #end()=
  #implement end
  def _end_  
    puts "end()" if VARS["debug"]
    context = CONTEXTS.last?
    if VARS["debug"]
      p! context  
    end

    if context
      if context.includes?("in_function") 
         @@current_line = STACK.pop  
         CONTEXTS.pop
         if VARS["debug"]
           print "popping/setting cul to: ",@@current_line+1,"\n"
           p! CONTEXTS 
         end  
        
         #lookup cfu, e.g. in caller context
          if CONTEXTS.size > 0 # back from an interactive function call 
            index = -1
            con = CONTEXTS[index]
            while !con.includes?("in_function")
              con = CONTEXTS[index]  #get context of caller
              index-=1
            end       
            Code.cfu = con.split(" ")[1]
          end  
          return # we already popped a context
        end 
       
      if context.includes?("in_if")
        if VARS["debug"]
         print "popping in_if\n"
         p! CONTEXTS 
        end 
        CONTEXTS.pop
        if CONTEXTS.last.includes?("skip")
          @@skip_lines = true
        else
          @@skip_lines = false
        end    
        p! CONTEXTS if VARS["debug"] 
        return
      end     

      if context.includes?("in_def")
        if VARS["debug"]
         print "popping in_def\n"
         p! CONTEXTS 
        end 
        CONTEXTS.pop
        if CONTEXTS.last.includes?("skip")
          @@skip_lines = true
        else
          @@skip_lines = false
        end    
        p! CONTEXTS if VARS["debug"] 
        return
      end     
    

    if context.includes?("in_while") 
        if VARS["debug"]
          print "while: line from context: ",(context.split(" ")[1]).to_i,"\n"
        end  
        skip = true if CONTEXTS.last.includes?("skip")
        if skip # end of while
          CONTEXTS.pop
          if CONTEXTS.last.includes?("skip")
            @@skip_lines = true
          else
            @@skip_lines = false
          end    
        else    # repeat while
          @@jmp_trigger = (context.split(" ")[1]).to_i-1
        end
        return
    end  
    
   else 
    puts "context lost"  
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
    CONTEXTS.push("in_if #{@@current_line+1}")

    if y == 3  # "if a < 2"
      varname, cmp , value = @@rols
       if cmp == "<" #check operator
        #result = _lower_("#{varname} #{cmp} #{value}", 3)
         if (@@functions[Code.cfu][varname].to_i < value.to_i)
           result = 1
         else
           result = 0
         end  
       elsif
        cmp == ">"
        #result = _higher_("#{varname} #{cmp} #{value}", 3)
         if (@@functions[Code.cfu][varname].to_i > value.to_i)
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
      _if_,varname,cmp,value = @@rols
      #p!  _if_, varname, cmp, value
      if @@functions[Code.cfu][varname].to_i == value.to_i   # equal ???
        result = 1
      else
        result = 0
      end
      print "result of if: ",result,"\n" if VARS["debug"]
    end

     # if true
     if y == 1   # if a - single token !
        cmp = @@rols[0]
           
        res=false

        if cmp   # double nil check
          value=cmp.to_i?
          if value 
            res = true if value > 0
          end    
        end

        p! cmp,Code.cfu
        if Code.functions[Code.cfu].has_key?(cmp)
          value = Code.functions[Code.cfu][cmp]
            
          if value.is_a? Int32 
             if value.to_i > 0
              res = true  
             end 
            end       
             
          if value.is_a? String 
            if value.size > 0
              res = true  
            end        
          end 
        end   

        res = false if cmp == "false"
 
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

#add_fun()=
def add_fun(name,vars,line)
  print "add_fun() " if VARS["debug"]
  @@functions[name] = { "line"  => line, "sign" => vars } 
end

# lower "<" operator
def _lower_(x : String, y : Int32)
  # counter < 10
  p! "lower()",x,y if VARS["debug"]
  varname, operand, val = @@rols
  value = val.to_i
  if Code.functions[Code.cfu][varname].to_i < value
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
   con = CONTEXTS # store current context on start of line, context may change later in the line
   varname = Code.rols[0]  
   if varname.to_i?
      print "numbers can't be var names\n"
      return
   end    
   value = Code.rols[3..].join(" ") # rest of line
   word = Code.rols[2]
   
   t,v = _typeof_(word,1) #is it a proc ?

   if t == "proc"
    if KWS.has_key?(word)
      y1 = y - 3 # we cant use y here, because it is already used !!!
                 # we call a proc inside a proc and share the same set of vars !!! 
      sv = KWS.[word].call(value, y1) #lookup and call procs
    #check result of call
    #get varnames as strings
      vnames = varname.split(",")
      index = 0
      vnames.each { |vname|   
         sx = sv[index]
          case sx
             when String 
               writevar(vname,sx) 
             when Int32
              writevar(vname,sx) 
             end      
         index+1
         }   
      return
    else 
      return
    end   
   end
  
  if t == "fun"   #is it a fun ?
   check_fun(word,x)   #pass the whole line to the called function, needed for return
   return
  end 

  value = Code.rols[2..].join(" ") # rest of line

   if (value[0] == '"' && value[-1] == '"')  # its a quoted string
      flag1 = true
   else
    flag1 = false
   end  

   if !(flag1 || value.to_i?)         # if its inside quotes or an int it is for sure no var
      value = check_name(value)     # lets see it the var really exists and get its value
   end  
   
   #check if we are in a function 
   #vars needs to be stored in function context
   writevar(varname,value)
end

#check_name()=
#check if a var with that name exists
#and return the value, give an error if not found
def check_name(x : String)
if VARS["debug"]
  puts "check_name():"
  p! Code.cfu,ROL[0],x if VARS["debug"]
end

  if x.to_i?    #just a number ?
    return x 
 end   

 if x.includes?(" ") #it is no valid varname, includes a blank
   return x 
 end
 
 if (x[0] == '"' && x[-1] == '"')  #just a quoted string
  return x 
 end 

#check proc 
if KWS.has_key?(x)
  sres,sval = KWS[x].call(ROL[0], Code.rols.size) #lookup and call proc functions
  #return sres  # checkname always returns a string !
  return sres.to_s
end  

#check if a interpreted function is called
#lookup,call function
flag = check_fun(x,ROL[0])
return x if flag == true

 #if Code.vars_int32.has_key?(x)
 # value = Code.vars_int32[x]
 # return value.to_s
 #end

 if Code.functions[Code.cfu].has_key?(x)
  value = Code.functions[Code.cfu][x].to_s
  value = value.gsub("_"," ")  # underscore -> blank
  value,flag = unquote value 
  return value
 end

 fn = "check_name"
 print fn + "():\n" if VARS["debug"]
 raise "Name: " + '"' + x + '"' + " not found"
end

#replace_var()=
#check if a var with that name exists
#and return the value, give no error
def replace_var(x : String)
  if x.to_i?    #just a number ?
     return x 
  end   
 
  if x.includes?(" ") #it is no valid varname, includes a blank
    return x 
  end
  
  if (x[0] == '"' && x[-1] == '"')  #just a quoted string
    return x
  end 
 
 #check if a interpreted function is called
 #lookup,call function 
 #flag = check_fun(x,ROL[0])
 #return x if flag == true
 
  if Code.vars_int32.has_key?(x)
   value = Code.vars_int32[x]
   return value.to_s
  end
 
  if Code.vars_string.has_key?(x)
   value = '"' + Code.vars_string[x] + '"'
   return value.to_s
  end

  if Code.functions[Code.cfu].has_key?(x)
    value = Code.functions[Code.cfu][x]
    return value.to_s 
  end
 
  fn = "replace_var"
  print fn + "():\n" if VARS["debug"]
  return x  # return self if var not found
 end
 
#lookup_var()=
#check if a var with that name exists
#and return the value
#give error when not found
def lookup_var(x : String)
  if x.to_i?    #just a number ?
     return x 
  end   
 
  if x.includes?(" ") #it is no valid varname, includes a blank
    return x 
  end

  if (x[0] == '"' && x[-1] == '"')  #just a quoted string
    return x
  end 
 
 #check local vars in function
 if Code.functions[Code.cfu].has_key?(x)
   varname = Code.functions[Code.cfu]
   varval = Code.functions[Code.cfu][x]
   return varval.to_s
 end 
 
if Code.vars_int32.has_key?(x)
 value = Code.vars_int32[x]
 return value.to_s
end
 
if Code.vars_string.has_key?(x)
  value = '"' + Code.vars_string[x] + '"'
  return value.to_s
end
 
fn = "lookup_var"
  print fn + "():\n" if VARS["debug"]
  print "var: " + '"' + x + '"' + " not found\n"
  return "nil"  # return error if var not found
end


#clear all vars in the hashes
def clear(x : String)
  #store line and args vars
  line = Code.functions[Code.cfu]["line"]
  sign = Code.functions[Code.cfu]["sign"]
  Code.functions[Code.cfu].clear  # clear 
  #restore line and args vars
  Code.functions[Code.cfu]["line"] = line
  Code.functions[Code.cfu]["sign"] = sign
end

#delete a var in the hashes
def _delete_(x : String)
  varname = x.split(" ")[0].to_s
  if Code.functions[Code.cfu].has_key?(varname) 
    Code.functions[Code.cfu].delete(varname)
  else
    raise ("var \"#{varname}\" not found")
  end    
end


# higher ">" operator
def _higher_(x : String, y : Int32)
  # counter > 10
  p! "higher()",x,y if VARS["debug"]
  varname, operand, val = Code.rols
  value = val.to_i
  if Code.functions[Code.cfu][varname].to_i > value
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
  elsif Code.functions.has_key?(x)
    res = "fun"; v=4
  elsif Code.vars_string.has_key?(x)
    res = "var-string"; v=5
  elsif Code.vars_int32.has_key?(x)
    res = "var-int32"; v=6
  else 
    res = "unknown type"; v=-1
  end
  Code.vars_string = Code.vars_string.merge({"typeof.result" => res}) 
  return res,v 
end  

#puts()=
def _puts_(x : String)
   puts check_args(x)
   return "nil",0
end   

#print()=
def _print_(x : String)
  print check_args(x)   
  return "nil",0
end 

#p()=
def _p_(x : String)
  _puts_(x)
end  


#def()=
#implmement functions
def _def_(x : String, y : Int32)
  if VARS["debug"]
    print "def()\n"
    print "found function definition: ",x
    print " in Line: ",Code.current_line+1,"\n"
  end
  line = Code.current_line
  name = x.split(" ")[0] # get the function name
  if y == 2 # when we get args
    vars = x.split(" ")[1]
    vars = vars[1..-2] # remove parens
  else  # no args, just a placeholder
    vars = "args"
  end  
  if name && line
    CONTEXTS.push("in_def #{Code.current_line+1}")
    Code.skip_lines=true 
    Code.add_fun(name,vars,line)
  end 
end  


#check_fun()=
def check_fun(word,rol)
  if VARS["debug"]
    print "check_fun() "
    p! word,rol 
  end
  if Code.functions.has_key?(word)
    Code.functions[word]["args"] = rol
    funstart = Code.functions[word]["line"]
    varname_from_sign = Code.functions[word]["sign"].to_s
    Code.functions[word][varname_from_sign] = replace_var(rol) # pass arguments to function by value
    if VARS["debug"]
      print "starting function: ",word," in line ",funstart.to_i+1,"\n" 
      print "pushing line: ",Code.current_line+1,"\n"
      p! word,rol,Code.functions[word]["sign"]
    end
    STACK.push(Code.current_line)
    CONTEXTS.push("in_function #{word}")
    Code.current_line = funstart.to_i
    Code.cfu=word
    p! CONTEXTS if VARS["debug"]
    if VARS["interactive"]
      Code.current_line+=1 if word != "main" # we do not want to run the def line, main has no def line
      Code.run("") 
    end  
    return true
   else
    return false
   end  
end  


#check the rest of line if names can be replaced
#by values or function results
#use before printing
#check_args()=
def check_args(rol)
if VARS["debug"] 
  puts "check_args()"
  p! rol  
end
if rol.size > 2
  if (rol[0] == '"' && rol[-1] == '"')  # whole args a quoted string ?
    rol,flag = unquote(rol)
    return rol
  end   
end    

return check_name(rol) if Code.rols.size < 2 # just one element

newrols=[] of String
if VARS["debug"]    
  puts "newrols" 
  p! Code.rols 
end    
Code.rols.each { |word| 
     p! word if VARS["debug"]  
     nres,flag = unquote(word) # quoted string ? 
     nres = check_name(nres) if flag == 1 # check if vars to replace 
   newrols << nres
   } 
p! newrols if VARS["debug"] 
return newrols.join(" ")  
end

#check the rest of line if names can be replaced
#by values or function results
#use before printing
#replace_vars()=
def replace_vars(rol)
  if rol.size > 0  
    if (rol[0] == '"' && rol[-1] == '"')  #just a quoted string
      return rol #return as it is
    end
  end    
  newrols=[] of String  
  Code.rols.each { |word| 
       res = replace_var(word) # check if vars to replace
     newrols << res
     } 
  
  return newrols.join(" ")  
  end

#return()
#implement return <val> from interpreted functions
def _return_(x : String, y : Int32)
  if VARS["debug"]
    print "return()\n"
    print "found return statement: ",x
    print " in Line: ",Code.current_line+1,"\n"
    print CONTEXTS,"\n"
  end
  if CONTEXTS.size >= 1
    if CONTEXTS.last.includes?("in_function")
      #cfu = CONTEXTS.last.split(" ")[1] #get current function name
      p! ROL[0],CONTEXTS if VARS["debug"]
      rol,flag = unquote(ROL[0])
      Code.functions[Code.cfu]["retval"] = rol #set the retval in fun() local namespace

      #search caller in contexts
      index = -2
      con = CONTEXTS[index]
      while !con.includes?("in_function")
        con = CONTEXTS[index]  #get context of caller
        index-=1
      end    
          if con.includes?("in_function")
          fu = con.split(" ")[1] #get function name
          fn_call = Code.functions[Code.cfu]["args"]
          fn_call_varname = fn_call.to_s.split(" ")[0] 
          Code.functions[fu][fn_call_varname] = rol
          p! fu, con, fn_call, fn_call_varname,rol if VARS["debug"] 
    end
   end 
 end
end  


def _system_(x : String)
  x,flag = unquote(x)
  cmd = x.split(" ")[0]
  args = [x.split(" ")[1..].join(" ")]
  p! cmd,args if VARS["debug"]
  args = nil if args == [""]
  status, output = run_cmd(cmd,args)  
  return output,status  
end  

def readvar(varname)
  return Code.functions[Code.cfu][varname]
 end

def writevar(varname,value)
   Code.functions[Code.cfu][varname] = value
end 