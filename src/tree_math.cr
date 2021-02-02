# add value to a var
# example:  counter+= 3
# "counter + = 3" # 4 token
# "a = b + 1"     # 5 token
def plus(x : String, y : Int32)
    p! "plus()",x,y if VARS["debug"]
    occ = x.count("+")
    if occ > 1
      fn = "plus"; method_err(fn,x)
    end  

    if y==3 # "a + b" 
       Code.rols = replace_vars(x).split(" ")
       in1,op,in2 = Code.rols
      return (in1).to_i + (in2).to_i 
    end

    if y==4 # "a + = 1" or "print a + b"
       res,op,assign,in2 = Code.rols
       if assign == "="
         writevar(res,readvar(res).to_i + in2.to_i) 
         return "nil"
       else
          proc,in1,op,in2 = Code.rols
          eval "#{proc} " + (in1.to_i + in2.to_i).to_s
       end     
    end   

    if y==5 # "r = a + b"
       res,assign,in1,op,in2 = Code.rols
       in1 = replace_var(in1)
       in2 = replace_var(in2) 
       writevar(res,in1.to_i + in2.to_i)
       return "nil"
    end   
end  
  
# sub value 
# example: counter-=3 
# "counter - = 3"     # 4 token
# "a = b - 1"         # 5 token
def minus(x : String, y : Int32)
  p! "plus()",x,y if VARS["debug"]
  occ = x.count("+")
  if occ > 1
    fn = "plus"; method_err(fn,x)
  end  
  
  if y==3 # "a + b"
     Code.rols = replace_vars(x).split(" ") 
     in1,op,in2 = Code.rols
    return (in1).to_i - (in2).to_i 
  end

  if y==4 # "a + = 1" or "print a + b"
     res,op,assign,in2 = Code.rols
     if assign == "="
       writevar(res,readvar(res).to_i - in2.to_i) 
       return "nil"
     else
        proc,in1,op,in2 = Code.rols
        eval "#{proc} " + (in1.to_i - in2.to_i).to_s
     end     
  end   

  if y==5 # "r = a + b"
     res,assign,in1,op,in2 = Code.rols
     in1 = replace_var(in1)
     in2 = replace_var(in2)
     writevar(res,in1.to_i - in2.to_i)
     return "nil"
  end   
end    


# mul value 
# example:  counter*= 3
# "counter * = 3" # 4 token
# "a = b * 1"     # 5 token
def mul(x : String, y : Int32)
  p! "plus()",x,y if VARS["debug"]
  occ = x.count("+")
  if occ > 1
    fn = "plus"; method_err(fn,x)
  end  

  if y==3 # "a + b" 
     Code.rols = replace_vars(x).split(" ")
     in1,op,in2 = Code.rols
    return in1.to_i * in2.to_i 
  end

  if y==4 # "a + = 1" or "print a + b"
     res,op,assign,in2 = Code.rols
     if assign == "="
       writevar(res,readvar(res).to_i * in2.to_i) 
       return "nil"
     else
        proc,in1,op,in2 = Code.rols
        eval "#{proc} " + (in1.to_i * in2.to_i).to_s
     end     
  end   

  if y==5 # "r = a + b"
     res,assign,in1,op,in2 = Code.rols
     in1 = replace_var(in1)
     in2 = replace_var(in2)
     writevar(res,in1.to_i * in2.to_i)
     return "nil"
  end   
end  

# div value 
# example:  counter*= 3
# "counter * = 3" # 4 token
# "a = b * 1"     # 5 token
def div(x : String, y : Int32)
  p! "plus()",x,y if VARS["debug"]
  occ = x.count("+")
  if occ > 1
    fn = "plus"; method_err(fn,x)
  end  

  if y==3 # "a + b"
     Code.rols = replace_vars(x).split(" ") 
     in1,op,in2 = Code.rols
    return (in1.to_i / in2.to_i).to_i 
  end

  if y==4 # "a + = 1" or "print a + b"
     res,op,assign,in2 = Code.rols
     if assign == "="
       writevar(res,((readvar(res).to_i / in2.to_i)).to_i) 
       return "nil"
     else
        proc,in1,op,in2 = Code.rols
        eval "#{proc} " + (in1.to_i / in2.to_i).to_i.to_s
     end     
  end   

  if y==5 # "r = a + b"
     res,assign,in1,op,in2 = Code.rols
     in1 = replace_var(in1)
     in2 = replace_var(in2)
     writevar(res,(in1.to_i / in2.to_i).to_i)
     return "nil"
  end   
end  

  
  # increment var value 
  def inc(x : String, y : Int32)
    if y == 1 
      Code.functions[Code.cfu][x] = Code.functions[Code.cfu][x].to_i + 1   
    else
      fn = "inc"
      method_err(fn,x) 
    end
    return "",0
  end
  
  # decrement var value 
  def dec(x : String, y : Int32)
    if y == 1
      Code.functions[Code.cfu][x] = Code.functions[Code.cfu][x].to_i - 1  
    else
      fn = "dec"
      method_err(fn,x) 
    end
    return "",0
  end
