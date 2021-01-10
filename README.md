# tree

tree is a dynamic testing environment for crystal functions

![](https://1.bp.blogspot.com/-Dhdk4jwtLYM/X_C7Lmrm62I/AAAAAAAAmgM/iBP_O6QceWoc7W0NETOR334k2xFUs60sQCLcBGAsYHQ/s1499/Peek%2B2021-01-02%2B19-17.gif)

It offers a CLI based REPL for interactive use.
It is fast(see performance) and scriptable. 
Debugging on function level offers single stepping.   
For debugging of single crystal expressions icr or crystal play should be used.    
Vars and functions are stored in hashes with public access  
via the CLI and your scripts.  


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

**Concept and syntax**  
The syntax is borrowed from crystal and ruby.  
Words in a line of code and operators are seperated(splitted)    
by blank when you load the file into the scripter.  
Comments are also removed, and some expressions like "==" are replaced
by "eq" and reparsed into lines with tokens. The program itself stays
readable with crystal/ruby like syntax in spite of this parsing.


Currently there are no parentheses supported.   
Operators can be added by writing additional wrappers  
around the crystal standard lib. Only one statement is allowed per line.  
Semicolon is not supported.


**Supported types for scripting**  
int32,string,proc,var-string,var-int32  

var-* types are a sort of pointer to a public var in a hash       

**Basic operators and their function name**  

\+   &ensp; plus()    
\-   &ensp; minus()    
\*   &ensp; mul()  
\    &ensp; div()  
=    &ensp; let() assign int or string to var or one var to another var    
==  &ensp; eq()  equal for numbers, TODO: equal for strings  
<    &ensp; lower()     
\>   &ensp; higher()   


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

>The type of a var it infered from the last assignment    
 
counter = "some_string"  
counter+ = 1   # example for a type mismatch Int32 vs String  
Error in: counter+=1  
Missing hash key: "counter"  # add function searches for int var named counter     

clear            #clear all user vars      
delete var name  #delete a user var  

**True and false vs 0,1**  
Functions return 0 on false, and 1 on true !  
There is no boolean type in the scripting environment.  
However the word "true" can be used for "while true"   

In the scripting environment:  
0     #false  
1     #true  
""    #empty strings are false  
"a"   #any string with a value is true  
var   #any var with a value > 0 or a string with size >0 is true  

The if operator can be used for true/false checks.  
I you want to see the result turn on debug.  


    Here a=1
    >if a
    eval: if a
    Line in: 
    if a
    Line splitted: 
    ["if", "a"]
    Word: if
    Rol: a
    x # => "a"
    y # => 1
    result of if: 1


**Print Strings, vars:**  
p \<var\>    
\# the var p.result is set to vars value for later use        
print "hello"   

**Loops:**  
While is supported by the scripter, have a look at after and every    
for scheduling functions  
TODO: nested loops  

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

foo = ""  init a var   
res = typeof \<foo\>  #get type of a var  
\>var-string  
                              
**Add your own functions:**    
-Edit tree.cr and add your favorite functions    
There is a hash with procs(function pointers) loaded at startup from tree.         

You need to follow the calling convention used in this  
proc hash, otherwise you get compile errors.  

If you need a different calling convention you can create  
your own proc hash table, but this might create some overhead.  

Current calling convention:  
function (String,Int32) String,Int32  

>every function must return values on exit  

Current functions:   
functions:  
typeof,print,eval,ceval,after+,-,inc,dec,<,>,if,while,every,ls,let,delete,clear,  
p,!,now,date,help,debug,singlestep,test,sleep,pass,end,cls,exit,load,run,  
split_run,list  


**Load,run,list,debug,singlestep a script:**    

    load filename   any comments and not needed blanks are removed from scripting code  
    run             run the loaded file  
    run s           single step by pressing return    
    singlestep      toggle single stepping of functions on/off  
    debug           Toggle debug output on/off    
    list            list the loaded script   

>Any function can be called during single stepping and vars can be checked
by just entering their name.  

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
eval \<statement\>  

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
