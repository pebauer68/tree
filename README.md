# tree

tree is a dynamic testing environment for crystal functions

It offers a CLI based REPL for interactive use.
It is fast(see Performance) and scriptable. 
Debugging on function level offers single stepping.   
For debugging of single commands icr or crystal play should be used.    
Vars and functions are stored in runtime extendable hashes   
with public access via the CLI.  

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
./tree filename # run a file with plain text    


**List vars, functions:**       
ls # list all  
ls vars  
ls functions   

    ls vars
    builtin vars: {"started" => false, "debug" => false, "filename" => "", "lines" => 0}
    user vars: 
    vars_int32: {"num" => 5}
    vars_string: {"day" => "thursday"} 

**Set,clear vars:**  
counter = 5   
name = "foo"  
counter+ = 2  
clear          #clear all user vars    

**Print Strings, vars:**  
p varname   
print "hello"   

**Loops:**
curently while is supported  
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
stop = 1       # stop all started timers        
               
**Add your own functions:**    
-look into tree.cr  
There is a hash with procs with functions loaded at startup from tree,       
and a register function for adding functions later, which are  
merged into this hash of procs.  
You need to follow the calling convention used in this  
proc hash, otherwise you get compile errors.  

If you need a different calling convention you can create  
your own proc hash table, but this might create some overhead.  

Current calling convention:  
function (String,Int32) Int32  # every function must return an int 

Current function table:   
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


**Load,run,list,debug a script:**    
load filename  
run   
run s  # single step by pressing return   
list  
Run a script from cli:  
./tree filename  

Toggle debug on/off:  
debug  

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
!icr     #use icr(interactive crystal), exit with ^D    
           #https://github.com/crystal-community/icr  


**Execute functions like they were typed in:**  
eval help  

**Eval via the crystal binary:**  
Expression is compiled and then executed.  
This will take about a second per evaluation.   
ceval 1+2  
ceval puts "aha"  
The result is stored as a string in the user var:  
ceval.result  

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
