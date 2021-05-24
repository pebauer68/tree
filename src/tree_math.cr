#plus()
#add value to a var
#example:  counter+= 3
#"counter + = 3" # 4 token
#"a = b + 1"     # 5 token
def plus(x : String, y : Int32)
    p! "plus()",x,y if Code.debug

    args,y,index = find_args("+") 
    if y==3 # "a + b" 
      in1,op,in2 = args
      in1,in2 = check_two_numbers(in1,in2)
      res = (in1 + in2).to_s
      res = res + " " + Code.rols[index+2..].join(" ") if index < Code.rols.size-3 # check if last expression
      res = Code.rols[..index-2].join(" ") + " " + res if index >=2
      return iterate(res)
    end

    if y==4 # "a + = 1" or "print a + b"
       res,op,assign,in2 = Code.rols
       if assign == "="
         in1,in2 = check_two_numbers(res,in2)
         if in1.class == Float64
          resval = add(in1.as(Float64),in2.as(Float64))
         else
          resval = add(in1.as(Int32),in2.as(Int32))
         end   
         writevar(res,resval)
         return "nil"
       else # "print a + b"
          proc,in1,op,in2 = args
          in1,in2 = check_two_numbers(in1,in2)
          res = Code.rols[..index-2].join(" ") + "," + (in1 + in2).to_s + "," + Code.rols[index+2..].join(" ") 
          p! res if Code.debug
          eval res
       end     
    end   

    if y==5 # "r = a + b"
       res,assign,in1,op,in2 = Code.rols
       in1,in2 = check_two_numbers(in1,in2) #int,float,string ?
       if in1.class == Float64
          resval = add(in1.as(Float64),in2.as(Float64))
       else
          resval = add(in1.as(Int32),in2.as(Int32))
       end   
       writevar(res,resval)
       return "nil"
    end  
    
end 

#iterate()
#over simple math operators
#until a single result is returned
def iterate(res)
  if Code.debug
    print "iterate() ",res,"\n"
  end  
  if res.includes?("*") || res.includes?("/") || res.includes?("+") || res[1..].includes?("-") || res.includes?(" ")
    eval res 
  else
    Code.rols = res.split(" ")
    return res
  end    
end

#find_args()
#find 2 args and the operatpr for math operation
def find_args(op : String)
  if Code.debug
    puts "in find_args()"
    p! op
  end  
  a = Code.rols
  index=0
  Code.rols.each_with_index { | str,i |
    if str == op  
       if i > 0   # do not break on "- 5"
         index=i 
         break
         end
    end  
      }  
  p! index if Code.debug     
  if index == 2 
    if Code.rols[0] == "-" # check for minus prefix
      Code.rols[1] = "-" + Code.rols[1] # move minus to first value
      res = Code.rols[index-1..index+1] # e.g. "-5 - 2"
      Code.rols.shift # delete "-" from first position   
      return res,3,1 # early return 
    end
  end  
  if Code.rols[index-1] == "+" # "a + - b"
    Code.rols[index-1] = Code.rols[index-2]
    res = Code.rols[index-1..index+1]
    return res,3,index
  end  
  res = Code.rols[index-1..index+1] # get the args before and after the op
  print "in find_args: ",res,"\n" if Code.debug
  type,n = _typeof_(Code.rols[0],1) if index == 3
  if type == "Proc"
    res.unshift Code.rols[0]  # insert proc like print or puts before rest of line
    return res,4,index   # print 1 + 2
  else 
    return res,3,index   # 1 + 2
  end   
end

def add(in1 : Float64, in2 : Float64)Float64
  return in1+in2
end

def add(in1 : Int32, in2 : Int32)Int32
  return in1+in2
end

#check_two_numbers()
#for their type
#and return numbers with the same type 
def check_two_numbers(in1,in2)
  p! "check_two_numbers()",in1,in2 if Code.debug
  in1 = replace_var(in1)
  in2 = replace_var(in2)
  if in1.class == String
     in1 = in1.as(String)
     if in1.includes?(".")
      in1 = in1.to_f
     else 
      in1 = in1.to_i
     end   
     elsif in1.class == Int32
        in1 = in1.as(Int32)
     elsif in1.class == Float64 
        in1 = in1.as(Float64)
          else
           raise "Unknown type"
          end

  if in2.class == String
     in2 = in2.as(String)
     if in2.includes?(".")
      in2 = in2.to_f
     else 
      in2 = in2.to_i
     end   
     elsif in2.class == Int32
        in2 = in2.as(Int32)
     elsif in2.class == Float64 
        in2 = in2.as(Float64)
          else
           raise "Unknown type"
          end

  if in1.class == Float64
     in2=in2.to_f
  end 
  if in2.class == Float64
    in1=in1.to_f
  end 
p! in1.class,in2.class if Code.debug  
return in1,in2
end

#minus()
#sub value 
#example: counter-=3 
#"counter - = 3"     # 4 token
#"a = b - 1"         # 5 token
def minus(x : String, y : Int32)
  p! "minus()",x,y if Code.debug
  
  args,y,index = find_args("-")
  
  if y==3 # "a - b" or "puts|print - b"
     in1,op,in2 = args
    if KWS.has_key?(in1)   # print -b
       return in2.to_i * -1
    else 
      in1,in2 = check_two_numbers(in1,in2) #int,float,string ?  
      res = (in1 - in2).to_s 
      res = res + " " + Code.rols[index+2..].join(" ") if index < Code.rols.size-3 # check if last expression
      res = Code.rols[..index-2].join(" ") + " " + res if index >=2
      return iterate(res)
    end
  end

  if y==4 # "a - = 1" or "print a - b" or "a = - b" or "a + - b"
     res,op,assign,in2 = Code.rols
     if assign == "="
       writevar(res,readvar(res).as(Int32) - in2.to_i)
       return "nil"
     elsif assign == "-" && res != "-"
        writevar(res,("-" + replace_var(in2).to_s).to_i)  
     else
        proc,in1,op,in2 = Code.rols
        eval "#{proc} " + (in1.to_i - in2.to_i).to_s
     end     
  end   

  if y==5 # "r = a - b"
     res,assign,in1,op,in2 = Code.rols
     in1,in2 = check_two_numbers(in1,in2) #int,float,string ?
       if in1.class == Float64
          resval = sub(in1.as(Float64),in2.as(Float64))
       else
          resval = sub(in1.as(Int32),in2.as(Int32))
       end   
       writevar(res,resval)
     return "nil"
  end   
end    

def sub(in1 : Float64, in2 : Float64)Float64
  return in1-in2
end

def sub(in1 : Int32, in2 : Int32)Int32
  return in1-in2
end

#mul()
#mul value 
#example:  counter*= 3
#"counter * = 3" # 4 token
#"a = b * 1"     # 5 token
def mul(x : String, y : Int32)
  p! "mul()",x,y if Code.debug

  args,y,index = find_args("*") 

  if y==3 # "a * b" 
     in1,op,in2 = args
     in1,in2 = check_two_numbers(in1,in2)
     res = (in1 * in2).to_s
     res = res + " " + Code.rols[index+2..].join(" ") if index < Code.rols.size-3 # check if last expression
     res = Code.rols[..index-2].join(" ") + " " + res if index >=2
     return iterate(res)
  end

  if y==4 # "a * = 1" or "print a * b"
     res,op,assign,in2 = Code.rols
     if assign == "="
      in1,in2 = check_two_numbers(res,in2)
      if in1.class == Float64
       resval = mul(in1.as(Float64),in2.as(Float64))
      else
       resval = mul(in1.as(Int32),in2.as(Int32))
      end   
      writevar(res,resval)
      return "nil"
    else # "print a * b"
       proc,in1,op,in2 = args
       in1,in2 = check_two_numbers(in1,in2)
       res = ""
       res = Code.rols[..index-2].join(" ") + "," + (in1 * in2).to_s + "," + Code.rols[index+2..].join(" ") 
       p! res if Code.debug
       eval res
    end     
 end    

  if y==5 # "r = a * b"
     res,assign,in1,op,in2 = Code.rols
     in1,in2 = check_two_numbers(in1,in2) #int,float,string ?
     if in1.class == Float64
        resval = mul(in1.as(Float64),in2.as(Float64))
     else
        resval = mul(in1.as(Int32),in2.as(Int32))
     end   
     writevar(res,resval)
   return "nil"
  end
end  

def mul(in1 : Float64, in2 : Float64)Float64
  return in1*in2
end

def mul(in1 : Int32, in2 : Int32)Int32
  return in1*in2
end

#div()
#div value 
#example:  counter/= 3
#"counter / = 3" # 4 token
#"a = b / 1"     # 5 token
def div(x : String, y : Int32)
  p! "div()",x,y if Code.debug

  args,y,index = find_args("/") 
 
  if y==3 # "a / b"
     in1,op,in2 = args
     in1,in2 = check_two_numbers(in1,in2)
     res = (in1 / in2).to_s
     res = res + " " + Code.rols[index+2..].join(" ") if index < Code.rols.size-3 # check if last expression
     res = Code.rols[..index-2].join(" ") + " " + res if index >=2
     return iterate(res)
  end

  if y==4 # "a / = 1" or "print a / b"
     res,op,assign,in2 = Code.rols
     if assign == "="
      in1,in2 = check_two_numbers(res,in2)
      if in1.class == Float64
       resval = div(in1.as(Float64),in2.as(Float64))
      else
       resval = div(in1.as(Int32),in2.as(Int32))
      end   
      writevar(res,resval)
      return "nil"
     else
        proc,in1,op,in2 = Code.rols
        in1,in2 = check_two_numbers(in1,in2)
        eval "#{proc} " + (in1 / in2).to_s
     end     
  end   

  if y==5 # "r = a + b"
     res,assign,in1,op,in2 = Code.rols
     in1,in2 = check_two_numbers(in1,in2) #int,float,string ?
       if in1.class == Float64
          resval = div(in1.as(Float64),in2.as(Float64))
       else
          resval = div(in1.as(Int32),in2.as(Int32))
       end   
       writevar(res,resval)
       return "nil"
    end    
end  

def div(in1 : Float64, in2 : Float64)Float64
  return in1/in2
end

def div(in1 : Int32, in2 : Int32)Int32
  return in1/in2
end

#inc()
#increment var value
#works for int32
#gives error for float 
def inc(x : String, y : Int32)
    if Code.debug 
       puts "in inc()"
       p! x,y 
    end   
    if y == 1 
      Code.functions[Code.cfu][x] = Code.functions[Code.cfu][x].as(Int32) + 1   
    else
      fn = "inc"
      method_err(fn,x,y) 
    end
    return "",0
  end
 
#dec()  
#decrement var value 
#works for int32
#gives error for float 
def dec(x : String, y : Int32)
    if y == 1
      Code.functions[Code.cfu][x] = Code.functions[Code.cfu][x].as(Int32) - 1  
    else
      fn = "dec"
      method_err(fn,x,y) 
    end
    return "",0
end