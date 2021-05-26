#code()=
#load,run,list code
#loop fuction: while, end 

STACK = [] of Int32         #line number stack used in functions
CONTEXTS = ["in_function main"]     #contexts like "in_while","in_if" are added at runtime

VARS = {
  "started"  => true,       #used in prompt() 
  "filename" => "",         #currrent file loaded
  "lines"    => 0,          #number of lines 
  "interactive" => true,    #more output in interaktive mode than in run mode
  "STDIN"    => STDIN       #but we do not write to stdout in an asignment e.g. a=now()
}

#method_err()
#args: (name,input string,number of args)
def method_err(fn,x,y)
  print "Method #{fn}\(\) failed, please check arguments\n"
  print "got: ", x,"\n"
  print "Number of args: ",y,"\n"
  puts Code.rols
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
       res = replace_vars(word) # check if vars to replace
     newrols << res.to_s
     } 
  
  return newrols.join(" ")  
  end



#check_fun()=
def check_fun(word,rol)
  if Code.debug
    print "check_fun() "
    p! word,rol 
  end
  if Code.functions.has_key?(word)
    Code.functions[word]["args"] = rol
    funstart = Code.functions[word]["line"].as(Int32)   
    varname_from_sign = Code.functions[word]["sign"].to_s
    if varname_from_sign != "noargs"
      Code.functions[word][varname_from_sign] = replace_vars(rol) # pass arguments to function by value
    end
    if Code.debug
      print "starting function: ",word," in line ",funstart,"\n" 
      print "pushing line: ",Code.current_line+1,"\n"
      p! word,rol,Code.functions[word]["sign"]
    end
    STACK.push(Code.current_line)
    CONTEXTS.push("in_function #{word}")
    Code.current_line = funstart
    Code.cfu=word
    p! CONTEXTS if Code.debug
    if VARS["interactive"]
      Code.current_line+=1 if word != "main" # we do not want to run the def line, main has no def line
      Code.run("") 
    end  
    return true
   else
    return false
   end  
end  



#check_name()=
#check if a var with that name exists
#and return the value, give an error if not found
def check_name(arg : String)
  if Code.debug
    puts "check_name():"
    p! Code.cfu,Code.rols,arg
  end
    return arg if arg.size == 0
  
    if arg.to_i?    #just a number ?
      return arg 
    end   
  
    if arg.to_f?
      return arg
    end  
  
   if arg.includes?(' ') #it is no valid varname, includes a blank
     return arg 
   end
   
   if (arg[0] == '"' && arg[-1] == '"')  #just a quoted string
    return arg 
   end 
  
  #check proc 
  if KWS.has_key?(arg)
    sres,sval = KWS[arg].call(Code.rol, Code.rols.size) #lookup and call proc functions
    #return sres  # checkname always returns a string !
    return sres.to_s
  end  
  
  #check if a interpreted function is called
  #lookup,call function
  flag = check_fun(arg,Code.rol) 
  return arg if flag == true
  
   #if Code.vars_int32.has_key?(x)
   # value = Code.vars_int32[x]
   # return value.to_s
   #end
  
  
  if Code.functions[Code.cfu].has_key?(arg)
    value = Code.functions[Code.cfu][arg].to_s
    value = value.gsub("\xc2\x9d"," ")  # special utf -> blank
    value,flag = unquote value 
    return value
  end
  
  begin
   if arg.includes?("[")  # read value from an array
    puts "read value from an array"
    varname,index = arg.split("[")
    index,rest = index.split("]")
    index = index.to_i
    value = readvar(varname).as(Array)[index]
    if value.as?(String)
      return value.as(String)
    elsif
      value.as?(Int32)
      return value.as(Int32)
    else
      value.as?(Float64)
      return value.as(Float64)
    end
   end 
  rescue
    puts "Error: Syntax Error during array parsing"
  end   
  
   fn = "check_name"
   print fn + "():\n" if Code.debug
   raise "Name: " + '"' + arg + '"' + " not found"
  end
  

#check the rest of line if names can be replaced
#by values or function results
#use before printing
#check_args()=
def check_args(rol,joinchar="")
  if Code.debug 
    puts "check_args()"
    p! rol  
  end
  if rol.size > 2
    if (rol[0] == '"' && rol[-1] == '"') && rol.count('"') == 2 # whole args a quoted string ?
      rol,flag = unquote(rol)
      return rol
    end   
  end    
  
  return check_name(rol) if Code.rols.size < 2 # just one element
  
  newrols=[] of String
  if Code.debug    
    puts "newrols" 
    p! Code.rols 
  end    
  Code.rols.each { |word| 
       p! word if Code.debug  
       nres,flag = unquote(word) # quoted string ? 
       nres = check_name(nres) if flag == 1 # check if vars to replace 
     newrols << nres.as(String)
     } 
  p! newrols if Code.debug 
  return newrols.join(joinchar)  
  end

#puts()=
def _puts_(x : String)
  puts check_args(x,joinchar="\n")
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



#typeof()=
def _typeof_(x : String, y : Int32)
  print "typeof() got: ",x,"\n"  if Code.debug
  res,v = "",0
  return res,v if y != 1   # check number of args
  if (x[0] == '"' && x[-1] == '"')   # a (quoted) string
    res = "String"; v=1
  elsif x.to_i?; 
    res = "Int32"; v=2
  elsif x.to_f?; 
    res = "Float64"; v=3
  elsif KWS.has_key?(x)
    res = "Proc" ; v=4
  elsif Code.functions.has_key?(x)
    res = "Fun"; v=5
  elsif Code.functions[Code.cfu].has_key?(x)  
    #res = "var"; v=6  
    val = Code.functions[Code.cfu][x]
    res,v = _typeof_(val.to_s,1)
    return  val.class.to_s,6
  elsif Code.vars_string.has_key?(x)
    res = "Var-string"; v=7
  elsif Code.vars_int32.has_key?(x)
    res = "Var-int32"; v=8
  else 
    res = "Unknown type"; v=-1
  end
  p! "returns type: ",res if Code.debug
  return res,v # string,value
end  


#readvar()
def readvar(varname,context=Code.cfu)  
  return Code.functions[context][varname]
 end

#writevar() 
def writevar(varname,value,context=Code.cfu)
   Code.functions[context][varname] = value
end 


module Code
    class_property codelines = [] of String
    # text based
    class_property splitlines = Array(Array(String)).new # all lines of code splitted 
    class_property rols = Array(String).new  #current line of code splitted in String array
    class_property singlestep = false
    class_property debug = false
    class_property log = false
    class_property lines = 0
    class_property current_line = 0
    class_property line = ""             #current line of code
    class_property injected_line = ""    #injected line of code
    class_property rol = ""
    class_property last_line = 0
    class_property vars_int32 = { } of String => Int32 
    class_property vars_string = { } of String => String
    class_property skip_lines = false
    class_property functions = { } of String => Hash(String,(String|Int32|Float64|Array(Int32|String|Float64)))  
    class_property cfu = "main"   # current function
    class_property inject = false
    class_property reader = IO::FileDescriptor.new(0, blocking: (LibC.isatty(0)) == 0)
    class_property writer = IO::FileDescriptor.new(0, blocking: (LibC.isatty(0)) == 0)

    @@jmp_trigger = -1
    @@current_line = 0
    @@running = false
    extend self
   
    #load()
    #load scripting code into the
    #codelines String array  
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
    #arg: s # single step mode on
    def run(arg)
      return if VARS["filename"] == ""
      VARS["interactive"] = false
      if arg == "s" 
        puts "press return - execute a single line"
        puts "press q to stop the program"
        puts "press c to continue run"
        Code.singlestep = true
      end    
      
      @@running = true
      @@skip_lines = false
      if CONTEXTS.size==0
        CONTEXTS.push("in_function main") 
        Code.cfu = "main"
      end
  
      size = @@codelines.size
      old = nil
      while @@line = @@codelines[@@current_line] # loop over code lines  -----------------------
        if Code.log
          timestamp = Time.monotonic
          diff = timestamp - old if old
          old = timestamp
          Tlog.info(diff.to_s + " " + (@@current_line+1).to_s + ":" + @@line)
        end
        if Code.debug
          timestamp = Time.local.to_s("%H:%M:%S.%6N")
          print "#{timestamp} Current line: ",@@current_line+1," has ",line.size," chars\n" 
          puts CONTEXTS
        end
  
        if !@@skip_lines
          print "evaluating: \"",@@line,'"',"\n" if Code.debug
          eval2(@@current_line)
        #elsif @@line.includes?("end") # skip these lines but take notice for context of blocks
        elsif @@splitlines[@@current_line][0] == "end" 
            #if @@line.split(" ",remove_empty: true)[0] == "end"
            #if Code.debug
            #  print "end found: ","in line: ",@@current_line+1,"\n"
            #end
             print "evaluating: \"",@@line,'"',"\n" if Code.debug
            Code._end_  # we need to call end to have the current context
            #end  
          elsif  # keep track of if/end context
            if @@line.includes?("if ")  
              CONTEXTS.push("in_if #{@@current_line+1} skip")
            end
             elsif  #keep track of while/end block
              if @@line.includes?("while ")  
                CONTEXTS.push("in_while #{@@current_line+1} skip")
              end
            else
            #puts "Skipping Line" if Code.debug
              end  # end of skip lines block ------------------------------------------------
  
        if @@jmp_trigger != -1 # we got a valid line number !?
            @@current_line = @@jmp_trigger.to_i 
            @@jmp_trigger = -1 # reset trigger
            #print "run(),Jumping to: ",@@current_line+1," ",@@codelines[@@current_line],"\n" if Code.debug
        else
          if Code.inject
            Code.inject()
          end    
          @@current_line += 1
        end  
        
        if Code.singlestep    # wait for any key
                puts "Press <enter> to singlestep,<c> to continue,<q> to quit "
                line=@@codelines[@@current_line].gsub("\n","\\n") # do not perform newlines, just print as "\n"
                #puts "Current line: #{@@current_line+1}: #{line}" if !Code.debug
                sread = STDIN.gets()
                while sread && sread.size > 1  # eval longer kwywords
                    eval(sread)
                    sread = STDIN.gets() 
                  end  
                if sread == "c"        # keys for single step mode
                  print "continue\n"
                  Code.singlestep = false
                end        
                if sread == "q"
                  print "stop\n"
                  Code.singlestep = false
                  return
                end
              end 
  
        break if @@current_line >= @@last_line
      end # of loop
      print "reached end of file in line: ",@@last_line,"\n" if Code.debug
      @@running = false
      @@current_line=0
      CONTEXTS.clear
      VARS["interactive"] = true
      Code.cfu="main"
    end # of run code
  
    #inject()
    #a line of code into a running interpreter session
    #via a text file with the name "line.txt" in the
    #current working dir
    #enable/disable on the command line with:
    #inject 
    def inject()
      if File.file?("line.txt")
        file = File.new("line.txt")
        if file.size > 0
          @@injected_line = file.gets_to_end.chomp 
          file.delete
          file.close
          eval(@@injected_line)
        end
      end  
    end
  
    #insert()=
    #a line of code into codelines
    #args: line number as Sting followed by a Blank char
    #and the code as String
    def insert(x,y)
      if y >= 2
        line = Code.rols[0].to_i
        code = Code.rols[1..].join(" ")
        @@codelines.insert(line,code)
        @@last_line+=1
      else # at least two args needed
        fn = "insert"
        method_err(fn,x,y) 
      end   
    end  
  
    #write()=
    #used to overwrite an existing codeline
    #args: line number as Sting followed by a Blank char
    #and the code as String
    def write(x,y) 
      if y >= 2
        line = Code.rols[0].to_i
        code = Code.rols[1..].join(" ")
        @@codelines[line-1]=code
      else # at least two args needed
        fn = "write"
        method_err(fn,x,y) 
      end   
    end
  
    #delete()=
    #a line of code by number from codelines
    #arg: line number as String
    def delete(x) 
      line = Code.rols[0].to_i
        code = Code.rols[1..].join(" ")
        @@codelines.delete_at(line-1)
        @@last_line-=1
    end 
    
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
        print "Current line:",@@current_line+1,"\n" if Code.debug
        print "Split line: ", line," ",line.size, "\n" if Code.debug
        ary = [] of String
        if (!(line.starts_with?("#") || line.size == 0 ))  # skip comment lines and empty lines
          ary = full_split(line)
          @@codelines[@@current_line] = ary.join(" ")  # write line back to codelines 
          @@splitlines << ary # write ary to split_lines
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
    #arg: "lines" or "splits"
    #default is "lines"
    def list(arg,default="lines")
      line=0
      arg = default if arg == ""
      while line < @@last_line
        if arg == "lines" 
          toprint = @@codelines[line]
          toprint = toprint.gsub("\n","\\n")
        end
        if arg == "splits"
          toprint = @@splitlines[line]
        end  
        print line+1,": ",toprint,"\n" 
        line += 1
      end  
    end
    
    #while()=
    #implement while
    def _while_(x : String, y : Int32)
      # while a < 77
      if Code.debug
         puts "in while()"
         p! x,y,@@rols 
      end


      if y == 3
        varname, cmp , value = @@rols
  
  
         if cmp == "<" #check operator
             if (@@functions[Code.cfu][varname].as(Int32) < value.to_i)
               #puts "while < is true: ",@@functions[Code.cfu][varname].as(Int32) if VARS ["debug"]
               result = 1
             else
               result = 0
             end   
         elsif
          cmp == ">"
          #result = _higher_("#{varname} #{cmp} #{value}", 3)
           if (@@functions[Code.cfu][varname].as(Int32) > value.to_i)
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
        
        flag = CONTEXTS.last.includes?("in_while #{@@current_line+1}") 
        if result == 0 # loop conditions for while not met   
          @@skip_lines = true
          if Code.debug
            print "set skip lines: true","\n" 
            p! CONTEXTS
          end
          CONTEXTS.pop if flag
          CONTEXTS.push("in_while #{@@current_line+1} skip") 
        else # loop conditions for while met
          CONTEXTS.push("in_while #{@@current_line+1}") if !flag 
        end   
        return
    end
  
    #end()=
    #implement end
    def _end_  
      if Code.debug
        puts "end()"
      end  
      context = CONTEXTS.last?
      #if Code.debug
      #  p! context  
      #end
  
      if context
        if context.includes?("in_function") 
           @@current_line = STACK.pop  
           CONTEXTS.pop
           #if Code.debug
           #  print "popping/setting cul to: ",@@current_line+1,"\n"
           #  p! CONTEXTS 
           #end  
          
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
          #if Code.debug
          # print "popping in_if\n"
          # p! CONTEXTS 
          #end 
          CONTEXTS.pop
          if CONTEXTS.last.includes?("skip")
            @@skip_lines = true
          else
            @@skip_lines = false
          end    
          #p! CONTEXTS if Code.debug 
          return
        end     
  
        if context.includes?("in_def")
          if Code.debug
           print "popping in_def\n"
           p! CONTEXTS 
          end 
          CONTEXTS.pop
          if CONTEXTS.last.includes?("skip")
            @@skip_lines = true
          else
            @@skip_lines = false
          end    
          p! CONTEXTS if Code.debug 
          return
        end     
      
  
      if context.includes?("in_while") 
          #if Code.debug
          #  print "while: line from context: ",(context.split(" ")[1]).to_i,"\n"
          #end  
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
  
      p! x,y if Code.debug
      CONTEXTS.push("in_if #{@@current_line+1}")
  
      if y == 3  # "if a < 2"
        varname, cmp , value = @@rols
         if cmp == "<" #check operator
          #result = _lower_("#{varname} #{cmp} #{value}", 3)
           if (@@functions[Code.cfu][varname].as(Int32) < value.to_i)
             result = 1
           else
             result = 0
           end  
         elsif
          cmp == ">"
          #result = _higher_("#{varname} #{cmp} #{value}", 3)
           if (@@functions[Code.cfu][varname].as(Int32) > value.to_i)
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
        if @@functions[Code.cfu][varname].as(Int32) == value.to_i   # equal ???
          result = 1
        else
          result = 0
        end
        print "result of if: ",result,"\n" if Code.debug
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
  
          print "result of if(): ",result,"\n" if Code.debug   
        end
  
        if result == 0 # if condition not met
          print "set skip lines: true","\n" if Code.debug    
          @@skip_lines = true
          return
        end
    end
    #end of if
  
  #add_fun()=
  def add_fun(name,vars,line)
    print "add_fun() " if Code.debug
    @@functions[name] = Hash(String, Array(Float64 | Int32 | String) | Float64 | Int32 | String).new
    #@@functions[name] = { "line"  => line, "sign" => vars, "val" => 0.0, "array" => [0,"nul",0.1] } 
    @@functions[name]["line"] = line 
    @@functions[name]["sign"] = vars
  end
  # lower "<" operator
  def _lower_(x : String, y : Int32)
    # counter < 10
    p! "lower()",x,y if Code.debug
    varname, operand, val = @@rols
    value = val.to_i
    if Code.functions[Code.cfu][varname].as(Int32) < value
      return 1
    else
      return 0
    end
  end
  
  end  
  #end of Code module