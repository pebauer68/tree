# tree

tree is a dynamic testing environment for crystal functions

## Installation

https://crystalshards.xyz/?filter=tree
install via crystal shards 

## Usage
./tree optional <filename>  


List vars, functions:   
ls # list all  
ls vars  
ls functions    

Set,clear vars:  
counter = 5   
name = foo  
counter+ = 2  
clear          #clear all user vars    

Print Strings, vars:  
p <varname>   
print hello    

Call functions:  
now            # display current time    
after 5 exit   # call exit in 5 seconds    
every 5 now    # Set timers to run <function> every 5 seconds    
               # here we just print the time    
               # stop all started timers by typing >stop = 1  

Load,run,list a script:  
load <filename>  
run   
run s  # single step by pressing return   
list  
Run a script from cli:  
./tree <filename>  

Execute shell commands by ! prefix:  
!pwd        
!icr     #use icr(interactive crystal), exit with ^D  
           #https://github.com/crystal-community/icr  

Toggle debug on/off:  
debug  

Execute functions like they were typed in:  
eval help  

Eval via the crystal binary:  
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
