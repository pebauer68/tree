# tree

tree is a dynamic testing environment for crystal functions

![](https://1.bp.blogspot.com/-Dhdk4jwtLYM/X_C7Lmrm62I/AAAAAAAAmgM/iBP_O6QceWoc7W0NETOR334k2xFUs60sQCLcBGAsYHQ/s1499/Peek%2B2021-01-02%2B19-17.gif)

It offers a CLI based REPL for interactive use.
It is fast(see performance) and scriptable. 
Debugging on function level offers single stepping.   
For debugging of single commands icr or crystal play should be used.    
Vars and functions are stored in runtime extendable hashes   
with public access via the CLI and your scripts.  


## Installation

https://crystalshards.xyz/?filter=tree  
install via crystal shards:    
add it to your shards.yml:  
  tree:  
    github: pebauer68/tree  
    branch: master  

cd to ./lib/tree  
make build  
make run  

or clone from Github:  
https://github.com/pebauer68/tree.git  


## Usage
**./tree # run tree interactive**  
./tree filename # run a script file with plain text    


**List vars, functions:**       
ls # list all  
ls vars       
ls functions   

    ls 
    builtin vars: {"started" => false, "debug" => false, "filename" => "", "lines" => 0}
    user vars: 
    vars_int32: {"num" => 5}
    vars_string: {"day" => "thursday"} 
    functions: run,split_run,list,print,load,eval,ceval,after,+,-,inc,dec  
    ,<,while,every,ls,let,delete,clear,p,!,now,help,debug,test,sleep,pass,end,cls,exit  

if you enter a var name and press return the var value will be shown.   
if you enter a function name it will be called.  

**Set,clear,delete vars:**  
counter = 5    # type Int32 is used
name = "foo"   # type String is used
counter+ = 2  
dynamic typing:  
counter = "7"  # set counter var to String "7" is possible  
               # the type of a var it infered from the last assignment
               # 
counter = "some_string"  
counter+ = 1   # example for a type mismatch Int32 vs String
Error in: counter+=1  
Missing hash key: "counter"  # add function searches for int var named counter    

clear            #clear all user vars    
delete var name  #delete a user var

**Print Strings, vars:**  
p var name 
\# the var p.result is set to varname for later use     
print "hello"   

**Loops:**
curently while is supported by the scripter 
have a look at after and every for scheduling functions  

    while counter < 100000  
        some_function
        counter+=1  
    end
      
    while true
      some_function  
    end      
    
**Performance:**
crystal build --release tree.cr  # compile with --release !

    time ../tree counter2.txt
    Loaded: counter2.txt Number of lines: 13
    code cleanup done in split_run()
    21:05:48.308013
    0
    1000000
    21:05:50.706197
    reached end of file

    real	0m2,401s 
    user	0m2,496s
    sys	0m0,103s
        
**Call functions:**  
now            # display current time via the now function   
after 5 exit   # call exit in 5 seconds    
every 5 now    # Set timers to run function every 5 seconds    
               # here we just print the time   
every 5 p a    # print value of var a to stdout every 5 seconds          
stop = 1       # stop all started timers 

functions can set a public var with the last result on exit:       
some_function.result = result                
               
**Add your own functions:**    
-Edit tree.cr and add your favorite functions    
There is a hash with procs(function pointers) loaded at startup from tree,       
and a register function for adding functions later, which are  
merged into this hash of procs.  
You need to follow the calling convention used in this  
proc hash, otherwise you get compile errors.  

If you need a different calling convention you can create  
your own proc hash table, but this might create some overhead.  

Current calling convention:  
function (String,Int32) Int32  # every function must return an int 

Current function table in tree.cr:  
KEYWORDS =  # list grows during runtime, when procs are added(via register function)  
    {"print", ->(x : String, y : Int32) { puts x; return 0 }},  
    {"load", ->(x : String, y : Int32) { Code.load x; return 0 }},  
    {"eval", ->(x : String, y : Int32) { eval x; return 0 }},  
    {"ceval", ->(x : String, y : Int32) { ceval x; return 0 }},  
    {"after", ->(x : String, y : Int32) { _after_(x, y); return 0 }},  
    {"+", ->(x : String, y : Int32) { plus(x, y) }},  
    {"-", ->(x : String, y : Int32) { minus(x, y) }},  
    {"inc", ->(x : String, y : Int32) { inc(x, y) }},  
    {"dec", ->(x : String, y : Int32) { dec(x, y) }},  
    {"<", ->(x : String, y : Int32) { lower(x, y) }},  
    {"while", ->(x : String, y : Int32) { Code._while_(x, y); return 0 }},  
    {"every", ->(x : String, y : Int32) { t = Timer.new; t.timer_test(x,y); return 0 }},  
    {"ls", ->(x : String, y : Int32) { ls(x,y); return 0 }},  
    {"let", ->(x : String, y : Int32) { let x; return 0 }}, 
    {"delete", ->(x : String, y : Int32) { delete x; return 0 }}, 
    {"clear", ->(x : String, y : Int32) { clear x; return 0 }},  
    {"p", ->(x : String, y : Int32) { _p_ x; return 0 }},  
    {"!", ->(x : String, y : Int32) { system(x); return 0 }},  
    {"now", ->(x : String, y : Int32) { puts Time.local.to_s("%H:%M:%S.%6N"); return 0 }},  
    {"help", ->(x : String, y : Int32) { help(x); return 0 }},  
    {"debug", ->(x : String, y : Int32) { VARS["debug"] = !VARS["debug"]; puts "debug is now:",VARS["debug"]; return 0 }},  
    {"test", ->(x : String, y : Int32) { procloop; return 0 }},  
    {"sleep",->(x : String, y : Int32) { sleep(x.to_i); return 0 }},  
    {"pass", ->(x : String, y : Int32) { pass; return 0 }},  
    {"end", ->(x : String, y : Int32) { Code._end_; return 0 }},  
    {"cls", ->(x : String, y : Int32) { print "\33c\e[3J"; return 0 }},  
    {"exit", ->(x : String, y : Int32) { exit(0) }},  


**Load,run,list,debug,singlestep a script:**    
load filename # any comments and not needed blanks are removed from scripting code
run           # run the loaded file 
run s         # single step by pressing return   
singlestep    # toggle single stepping of functions on/off
debug         # Toggle debug output on/off:  
list          # list the loaded script

Run a script from cli:  
./tree filename  

    Example for debug output:  
    
    Current line: 4 has 17 chars
    "while counter < 5"
    eval: while counter < 5
    Word: while
    Rol: counter < 5
    x # => "counter < 5"
    y # => 3

**Execute shell commands by ! prefix:**    
!pwd        
!icr #use icr(interactive crystal), exit with ^D    
https://github.com/crystal-community/icr  


**Execute functions like they were typed in:**  
eval help  

**Eval via the crystal binary:**  
Expression is compiled and then executed.  
This will take about a second per evaluation.   
ceval 1+2  
ceval puts "aha"  
\# the var ceval.result is set for later use  

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/pebauer68/tree/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Peter Bauer](https://github.com/pebauer68) - creator and maintainer
