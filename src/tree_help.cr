def help(arg)
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
  >print or puts "hello" or <varname>    
  
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

  if arg.size == 0
    puts helptext
  else
    puts "Searching for help on: #{arg}"
    search_help(arg)
  end
end

def search_help(arg)
  files = ["kws.cr", "tree.cr", "code.cr", "quoted.cr", "tree_math.cr", "ipc.cr", "log.cr"]
  pwd = readvar("pwd").as(String)
  puts "Seach in path: #{pwd}"

  files.each { |filename|
    fname = pwd + "/" + filename
    puts fname
    stext = File.open(fname).gets_to_end

    ln = 1
    pflag = false
    stext.each_line { |line|
      if filename != "kws.cr"
        prefix = "#"
        trigger = "()"
        oneline = false
      else
        prefix = ""
        trigger = ""
        oneline = true
      end

      pflag = true if line.includes?(prefix + arg + trigger) # trigger start on help header with ()

      if pflag
        puts ln.to_s + " : " + line
        if line.includes?("def ") | oneline # trigger end on function signature
          pflag = false
        end
      end
      ln += 1
    } # all lines done

  } # all files done
end
