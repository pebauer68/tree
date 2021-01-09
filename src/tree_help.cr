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