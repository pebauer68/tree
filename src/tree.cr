#require "readline"         #its better to use the rlwrap readline wrapper 
                            #from the shell: #rlwrap ./tree 
require "./code.cr"         #split,run code,while,end,...                   
require "./quoted.cr"       #handling chars in quotes
require "./kws.cr"          #keywords proc hash table
require "./tree_help.cr"    #help function
require "./tree_math.cr"    #simple int and float math 
require "./ipc.cr"          #ipc with ruby 3.0


Code.log = true
IPCIN = [] of String        #store ipc results as string
OP = {"eq","=","/","*","-","+","append"}  #supported operators, first op has highest prio
Code.add_fun("main","noargs",0)       #add a namespace for main
Code.add_fun("eval","noargs",0)       #add a namespace for eval, e.g. used by Array.new()
Code.cfu="main"                       #current function is main on startup
writevar("trace",0)                   #set the trace var to 0
writevar("pwd",Dir.current())         #store working dir path in var pwd

puts "Welcome to tree"                #welcome banner
require "./log"                       #start a logger, use it with log(msg)

if ARGV.size == 1 && ARGV[0].size > 0    # check if a filename with length > 0 is passed
  file = ARGV[0]                         # get the filename
  eval("load #{file}")
  eval("run")
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
    if VARS["filename"].to_s.size > 1
      print "Error in: #{line}\n", ex.message, "\n"
      if Code.current_line > 0
        print "in File: #{VARS["filename"]} Line: #{Code.current_line+1}\n"
      end  
    else
      print "Error: ",ex.message, "\n"
    end    
      if Code.functions["main"]["trace"] == 1
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
  print ">"
end

#ls()=
#list VARS and/or functions
def ls ( x : String, y : Int32)
  p! x,y if Code.debug
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
    print "current line: ",Code.current_line+1,"\n"
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
  print "eval(): ",line,"\n" if Code.debug
  word = nil 
  if line && line != ""
    Code.line = line
    Code.rols = full_split(line)         # needs full split which is a bit slower
    return if Code.rols.size == 0        # check needed for lines with blanks

    Code.rols[1..].each { |token|            # check for operators in line(array)
                                             # OP = {"eq","=","/","*","+","-"}                      
      if OP.includes?(token)  
        if "+-".includes?(token) # check simple math operators
            if Code.rols[1..].includes?("*") || Code.rols.includes?("/")
              next # process "*/" before "+-"
            else 
             word=token 
            break
          end 
        end     
        word=token # no math operators found
        break
      end
    }  

    if Code.rols[0] == "help"             # check only in interactive mode 
       word = nil  # help function overrules all, do not trigger on operators
    end
    word = Code.rols.shift if !word       # get first word
    Code.rol = Code.rols.join(" ")        # rest of line
  
    
    if word.includes?(".")          # support dot naming
      dntree = word.split(".")      # consume the first elem, parse the rest
      word = dntree[0]              # get parent name
      res = ""   
      if Code.rol.size > 0
        res = dntree[1..].join(".")
        Code.rol = res + " " + Code.rol         # "a.b.c (123)"
      else
        res = dntree[1..].join(".")   # "a.b.c"    
        Code.rol = res   
      end     
    end

    if Code.debug
      print "Word: ",word,"\n" 
      print "Rol: ",Code.rol,"\n" 
    end

    if KWS.has_key?(word)
      sres,sval = KWS[word].call(Code.rol, Code.rols.size) #lookup and call proc functions
      if VARS["interactive"]
        puts sres if (sres != "nil" && sres.to_s.size > 0)
      else
      end    
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
def eval2(ind)
    word = nil
    #Code.rols = line.split(" ") # here simple split is used which is faster
    Code.rols = Code.splitlines[ind].dup 

    Code.rols[1..].each { |token|            # check for operators in line(array)
                                             # OP = {"eq","=","/","*","+","-"}                      
      if OP.includes?(token)   
        if "+-".includes?(token)
          if Code.rols[1..].includes?("*") || Code.rols.includes?("/")
             next
          else
           word=token
           break
          end 
        end     
        word=token 
        break
      end
    }  
    
    
    word = Code.rols.shift if !word     # just get first word of line if we found no operator
    Code.rol = Code.rols.join(" ")      # rest of line as String
  

    if word.includes?('.')              # support dot naming
      word,word2 = word.split(".") 
      if Code.rol.size > 0
        Code.rol = word2 + " " + Code.rol    # "a.b 123"
      else
        Code.rol = word2
      end   
    end

    #if Code.debug
    #  print "eval2(): ",line,"\n" 
    #  print "Word: ",word,"\n" 
    #  print "Rol: ",rol,"\n"
    #end   

    if KWS.has_key?(word)
      sres,sval = KWS[word].call(Code.rol, Code.rols.size)  #check for proc functions
      puts sres if (sres != "nil" && sres.to_s.size > 0)
    elsif
      res = check_name(word)       #check for vars, functions
      puts res if res != word      #write var value or functions result to stdout
    end
end # end of eval2()

def check_equal(line : String)
    pos = line.index("==")
    pos = line.index("= =") if !pos
    if pos
     res = !inside_quotes?('"',line,pos)
    else
     res = false
    end 
    #p! line,pos,res if Code.debug
    return res  
end

#eval a line by  
#passing the line to the crystal binary 
def ceval(line)
  #print "eval: ",line,"\n" if Code.debug
  if line && line != ""
    line = "puts " + line
    cmd  = "crystal"
    args = ["eval", line]
    status, output = run_cmd(cmd, args)
    puts output  
    # set user var
    writevar("ceval.result",output.chomp)  
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
  puts "full_split(): ", line if Code.debug
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
  #handle assignment/equal operator
  ind = line.index("=  =") 
    if ind
     flag = inside_quotes?('"',line,ind)
     if !flag   
        line=line.gsub("=  =","eq")
     end
    end 

  #handle append < <
  ind = line.index("<  <") 
    if ind
     flag = inside_quotes?('"',line,ind)
     if !flag   
        line=line.gsub("<  <","append")
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
    
  #replace blanks inside quotes with seldom used utf char 
  #see check_name where its is replaced with blank when reading var values
  offset = 0
   while offset < line.size
      ind = line.index(" ",offset)
      if ind
       flag = inside_quotes?('"',line,ind)
       if flag  
         line = line.sub(ind,"") 
         line = line.insert(ind,"\xc2\x9d") # seldom used utf char, gets printed to stdout as blank
         #line = line.insert(ind,"_")
       end
    end   
    offset+=1
  end

  #handle "\\n", newline is done 
  line=line.gsub("\\n","\n")


  #remove commas not needed
  #we need commas for assignment  a,b = proc()
  #and function signature: def fn(a,b,c)
  #we need to keep kommas inside quotes "123,456"
  
  ind = line.index(" = ") # do we have an assignment here ?
  if ind 
     flag = inside_quotes?('"',line,ind) # assignment quoted ?
  else
     flag = true
  end      
  if flag # lets replace commas with blank 
    offset = 0
    while offset < line.size
       ind = line.index(",",offset)
       if ind
        flag = inside_quotes?('"',line,ind)
        if !flag # only replace when not quoted  
          line = line.sub(ind,"") 
          line = line.insert(ind," ")
        end
     end   
     offset+=1
   end
  end  

  #split

  line.split(" ", remove_empty: true) { |string|
    break if string[0] == '#'     # remove comments
    ary << string                 # "a+=1" ->  ["a", "+", "=", "1"]
  }
  puts "Line splitted: ", ary if Code.debug
  return ary
end

class Timer
  @@name ="Timer"
  @@inst=0

  def initialize
    @@inst+=1
    puts "New instance starting: ",@@inst
  end  

# x = job,interval
def start_timer(x , y)
if y >=2
  interval = x.split(" ")[0]
  job = x.split(" ")[1..].join(" ") # get the rest of line
    puts "timer #{@@inst} started with interval: #{interval}" 
    eval ("stop = 0")
    return if interval == ""
    
    puts "Message from Timer, type:\n>stop = number or -1 to stop all started timers"
    writevar("timer.instances",@@inst,context="main")

    inst = @@inst # handle the current instance
    spawn {   #spawn this timer job block and return
      loop do
        writevar("timer.inst.#{inst}","job=\"#{job}\"",context="main")
        eval job   
        sleep interval.to_i
        if readvar("stop",context="main").as(Int32) == -1 || readvar("stop",context="main").as(Int32) == inst 
          puts "timer #{inst} stopped"
          eval "delete timer.inst.#{inst}"  
          break
        end   
      end
    }
    return "",inst
 else
  puts "Method needs at least 2 arguments"
  return "",0
 end 
end 

end #end of class Timer

#after()
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
  proc = {->pass}
  1000000.times {
    proc[0].call
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
#<myintvar> = 7
#<mystringvar> = "some test"
#a = b
def let(x : String,y : Int32)
   if Code.debug
    p! "let()",x,y
    p! Code.rols 
   end

   con = CONTEXTS # store current context on start of line, context may change later in the line
   varname = Code.rols[0]  
   if varname.to_i?
      print "numbers can't be var names\n"
      return
   end

   mode = VARS["interactive"] 
   VARS["interactive"] = false # do not write to stdout in assignment

   if y > 4 # something to calculate ? e.g. "a = 1 +", reduce to a single value
     assign = Code.rols[..1]
     args = Code.rols[2..]
     eval args.join(" ") # eval the right side of the expression after the "="
     Code.rols = assign + Code.rols[..2]  
   end   

   VARS["interactive"] = mode

   varname = varname.consume_cfu()
   value = Code.rols[3..].join(" ") # rest of line
   word = Code.rols[2]
   
   t,v = _typeof_(word,1) #is it a proc ?
   
   if t == "Proc"
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
         index+=1
         }   
      return
    else 
      return
    end   
   end
  
  if t == "Fun"   #is it a fun ?
   check_fun(word,x)   #pass the whole line to the called function, needed for processing return
   return
  end 

  value = Code.rols[2..].join(" ") # rest of line

  if t == "Float64"
    writevar(varname,value.to_f)
    return
  end

   if (value[0] == '"' && value[-1] == '"')  # its a quoted string
      flag1 = true
   else
    flag1 = false
   end  

   if !(flag1 || value.to_i?)       # if its inside quotes or an int it is for sure no var
      value = check_name(value)     # lets see it the var really exists and get its value
   end  

  if t == "Var"
    writevar(varname,value)  
    return
  end

  if t  == "String"   
      value = value.as(String)    # is needed for calling unquote
      #Error: no overload matches 'unquote' with type (Float64 | Int32 | String)
      value,flag = unquote(value)            
      writevar(varname,value) 
      return  
   end   


   if t  == "Int32"            #if input is an int then store as int  
    writevar(varname,value.to_i)
    return
    end
  

  if t == "Unknown type"
    if Code.rols[2].includes?(".")       # support dot naming
      word,word2 = word.split(".")       # first use for Array.new() 
      lside,rside = Code.rol.split("= ")
      p! lside,rside
       eval(rside)  
       writevar(varname,Code.functions["eval"]["res"])
    end   
  end
  
end


#replace_var()=
#check if a var with that name exists
#and return the value, give no error
def replace_var(x : String)
  p! x if Code.debug
  return x if x.size == 0
   
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
    return value 
  end
 
  fn = "replace_var"
  print fn + "():\n" if Code.debug
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
  print fn + "():\n" if Code.debug
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

#delete()
#delete a var by name in the hash
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
  p! "higher()",x,y if Code.debug
  varname, operand, val = Code.rols
  value = val.to_i
  if Code.functions[Code.cfu][varname].as(Int32) > value
    return 1
  else
    return 0
  end
end


#def()=
#implmement functions
def _def_(x : String, y : Int32)
  if Code.debug
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
    vars = "noargs"
  end  
  if name && line
    CONTEXTS.push("in_def #{Code.current_line+1} skip")
    Code.skip_lines=true 
    Code.add_fun(name,vars,line)
  end 
end  

#return()
#implement return <val> from interpreted functions
def _return_(x : String, y : Int32)
  if Code.debug
    print "return()\n"
    print "found return statement: ",x
    print " in Line: ",Code.current_line+1,"\n"
    print CONTEXTS,"\n"
  end
  if CONTEXTS.size >= 1
    if CONTEXTS.last.includes?("in_function")
      #cfu = CONTEXTS.last.split(" ")[1] #get current function name
      p! CONTEXTS if Code.debug
      rol,flag = unquote(Code.rols[0])
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
          p! fu, con, fn_call, fn_call_varname,rol if Code.debug 
    end
   end 
 end
end  

#system()
#make system call
#return result as String
def _system_(x : String)
  x,flag = unquote(x)
  cmd = x.split(" ")[0]
  args = [x.split(" ")[1..].join(" ")]
  p! cmd,args if Code.debug
  args = nil if args == [""]
  status, output = run_cmd(cmd,args)  
  return output,status  
end  


#construct a new array
#store the array in function "eval" context
#Array.new(1,2,3) 
def _array_(x : String, y : Int32)
  method,param = x.split(" (") # split after the "w" of "new"
  param = param[0..-2]  # remove ()
  p! param,method
  if method == "new"
      params = param.split(" ")
      a = Array(String|Int32|Float64).new
      params.each { |elem|
       r, flag = unquote(elem)
       if r.to_i?
          r=r.to_i if flag == 1
       end
       if r.class == (String) 
          r=r.as(String)
          if r.includes?(".") # translate to float
             r=r.to_f if flag == 1
          end    
       end    
       a << r
       }
     a.clear if param.size == 0  
     Code.functions["eval"]["res"] = a.as(Array(String|Int32|Float64))
  end
end  

#append() to an array
# "a << b"
# of type Int32|String|Float64
def _append_(x : String, y : Int32)
  method_err("append",x,y) if y !=3  # 3 tokens expected here
  namea, append, nameb = Code.rols
  if Code.debug
    p! x,y,namea, append, nameb
  end  
  invar = check_name(nameb) # can be a value or a proc or function
  invar,flag = unquote(invar.as(String))
  invar = invar.to_i if invar.to_i? && flag == 1  # convert string to number if not quoted
  Code.functions[Code.cfu][namea].as(Array) << invar # finally append to var name in function context
end  

#consume() first part of dot named varname 
#if name matches current function
class String
  def consume_cfu
      if self.starts_with?(Code.cfu)
         return self[Code.cfu.size+1..]
      else
         return self   
      end
  end      
end  