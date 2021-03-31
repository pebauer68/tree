# add value to a var
# example:  counter+= 3
# "counter + = 3" # 4 token
# "a = b + 1"     # 5 token
def plus(x : String, y : Int32)
    p! "plus()",x,y if VARS["debug"]
    occ = x.count("+")
    if occ > 1 
      fn = "plus"; method_err(fn,x)
      return 
    end 

    if y==3 # "a + b" 
      in1,op,in2 = Code.rols
      in1,in2 = check_two_numbers(in1,in2)
      return in1 + in2 
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
          proc,in1,op,in2 = Code.rols
          in1,in2 = check_two_numbers(in1,in2)
          eval "#{proc} " + (in1 + in2).to_s
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

def add(in1 : Float64, in2 : Float64)Float64
  return in1+in2
end

def add(in1 : Int32, in2 : Int32)Int32
  return in1+in2
end


def check_two_numbers(in1,in2)
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
return in1,in2
end
  
# sub value 
# example: counter-=3 
# "counter - = 3"     # 4 token
# "a = b - 1"         # 5 token
def minus(x : String, y : Int32)
  p! "minus()",x,y if VARS["debug"]
  occ = x.count("+")
  if occ > 1
    fn = "plus"; method_err(fn,x)
  end  
  
  if y==3 # "a - b" or "puts|print - b"
     Code.rols = replace_vars(x).split(" ") 
     in1,op,in2 = Code.rols
    if KWS.has_key?(in1)
       return in2.to_i * -1
    else 
      in1,in2 = check_two_numbers(in1,in2) #int,float,string ?  
      if in1.class == Float64
        resval = sub(in1.as(Float64),in2.as(Float64))
      else
        resval = sub(in1.as(Int32),in2.as(Int32))
      end   
       return resval 
    end
  end

  if y==4 # "a - = 1" or "print a - b" or "a = - b"
     res,op,assign,in2 = Code.rols
     if assign == "="
       writevar(res,readvar(res).as(Int32) - in2.to_i)
       return "nil"
     elsif assign == "-"
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



# mul value 
# example:  counter*= 3
# "counter * = 3" # 4 token
# "a = b * 1"     # 5 token
def mul(x : String, y : Int32)
  p! "mul()",x,y if VARS["debug"]
  occ = x.count("*")
  if occ > 1
    fn = "plus"; method_err(fn,x)
  end  

  if y==3 # "a * b" 
     Code.rols = replace_vars(x).split(" ")
     in1,op,in2 = Code.rols
     in1,in2 = check_two_numbers(in1,in2)
     return in1 * in2
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
       proc,in1,op,in2 = Code.rols
       in1,in2 = check_two_numbers(in1,in2)
       eval "#{proc} " + (in1 * in2).to_s
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



# div value 
# example:  counter/= 3
# "counter / = 3" # 4 token
# "a = b / 1"     # 5 token
def div(x : String, y : Int32)
  p! "div()",x,y if VARS["debug"]
  occ = x.count("+")
  if occ > 1
    fn = "plus"; method_err(fn,x)
  end  

  if y==3 # "a / b"
     Code.rols = replace_vars(x).split(" ") 
     in1,op,in2 = Code.rols
     in1,in2 = check_two_numbers(in1,in2)
     return (in1 / in2)
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

  
  # increment var value
  # works for int32
  # gives error for float 
  def inc(x : String, y : Int32)
    if y == 1 
      Code.functions[Code.cfu][x] = Code.functions[Code.cfu][x].as(Int32) + 1   
    else
      fn = "inc"
      method_err(fn,x) 
    end
    return "",0
  end
  
  # decrement var value 
  def dec(x : String, y : Int32)
    if y == 1
      Code.functions[Code.cfu][x] = Code.functions[Code.cfu][x].as(Int32) - 1  
    else
      fn = "dec"
      method_err(fn,x) 
    end
    return "",0
  end
