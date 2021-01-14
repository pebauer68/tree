# add value to a var
# example:  counter+= 3
# "counter + = 3" # 4 token
# "a = b + 1" works # 5 token
# "fun() x + y" # 4 token
def plus(x : String, y : Int32)
    p! "plus()",x,y if VARS["debug"]
    occ = x.count("+")
    if occ > 1
      fn = "plus"; method_err(fn,x); return 0
    end  
    if y==3 # "a+b" in interaktive mode
       res1 = check_if_var(x.split[0])
       res2 = check_if_var(x.split[2])
       if (res1 == "nil" || res2 == "nil")
           fn = "plus"; method_err(fn,x); return 0
       end
       x = "print " + x 
       y = 4
    end
  
    if y==4 && !(x.includes?("="))  # fun() x + y 
       lside = x.split[0]
       rside = x.split[1..].join(" ")
       x = lside + " = " + rside
       y=5
    end
  
    if y == 5 # countera = counterb + 1
       lside, rside = x.split(" = ",remove_empty: true)
       p! rside, lside if VARS["debug"]
       rside_s = rside.split(" ",remove_empty: true)
       #if "a = a + 1"
       rside_s.insert(2,"=")
       rside_j = (rside_s.join(" "))
       if lside == rside_s[0]
        x = rside_j # rewrite "counter = counter + 1" to "counter + = 1"
        y = 4
       else  # numeric int only !
        #rside_res = rside_s[0].to_i + rside_s[3].to_i
        val1 = check_if_var(rside_s[0])
        val2 = check_if_var(rside_s[3])
        if (val1 == "nil" || val2 == "nil")
          fn = "plus"; method_err(fn,x); return 0
        end
        rside_res = val1.to_i + val2.to_i
        if KWS.has_key?(lside)                # do we have a function on left side ?
          KWS[lside].call(rside_res.to_s,1)   # give result as string
          return 0
        end  
        Code.vars_int32[lside] = rside_res    # store result in var
        p! rside_res if VARS["debug"]
        return 0
       end
       p! rside_s,rside_j,rside_res if VARS["debug"]
       #return 0
    end 
    if y == 4 # counter + = 3  
      varname = x.split(" ")[0]
      value = x.split(" ")[3].to_i
      if Code.vars_int32.has_key?(varname)
        Code.vars_int32[varname] += value
      end  
    else
      fn = "plus"
      method_err(fn,x) 
    end
    return 0
  end
  
  # subtract value from a var
  # example:  counter-= 3
  # splitted: counter - = 3
  def minus(x : String, y : Int32)
    p! x if VARS["debug"] 
    occ = x.count("-")
    if occ > 1
      fn = "minus"; method_err(fn,x); return 0
    end  
    if y==3 # "a-b" in interaktive mode
      res1 = check_if_var(x.split[0])
      res2 = check_if_var(x.split[2])
      if (res1 == "nil" || res2 == "nil")
          fn = "minus"; method_err(fn,x); return 0
      end
      x = "print " + x 
      y = 4
   end
   if y==4 && !(x.includes?("="))  # fun() x + y 
    lside = x.split[0]
    rside = x.split[1..].join(" ")
    x = lside + " = " + rside
    y=5
 end

 if y == 5 # countera = counterb - 1
    lside, rside = x.split(" = ",remove_empty: true)
    p! rside, lside if VARS["debug"]
    rside_s = rside.split(" ",remove_empty: true)
    #if "a = a + 1"
    rside_s.insert(2,"=")
    rside_j = (rside_s.join(" "))
    if lside == rside_s[0]
     x = rside_j # rewrite "counter = counter - 1" to "counter - = 1"
     y = 4
    else  # numeric int only !
     #rside_res = rside_s[0].to_i + rside_s[3].to_i
     val1 = check_if_var(rside_s[0])
     val2 = check_if_var(rside_s[3])
     if (val1 == "nil" || val2 == "nil")
       fn = "plus"; method_err(fn,x); return 0
     end
     rside_res = val1.to_i - val2.to_i
     if KWS.has_key?(lside)                # do we have a function on left side ?
       KWS[lside].call(rside_res.to_s,1)   # give result as string
       return 0
     end  
     Code.vars_int32[lside] = rside_res    # store result in var
     p! rside_res if VARS["debug"]
     return 0
    end
    p! rside_s,rside_j,rside_res if VARS["debug"]
    #return 0
 end 
 if y == 4 # counter + = 3  
   varname = x.split(" ")[0]
   value = x.split(" ")[3].to_i
   if Code.vars_int32.has_key?(varname)
     Code.vars_int32[varname] -= value
   end  
 else
   fn = "minus"
   method_err(fn,x) 
 end
 return 0
end
  
# mul value from a var
# example:  val*= 3
# splitted: val * = 3
def mul(x : String, y : Int32)
    p! x if VARS["debug"] 
    occ = x.count("*")
    if occ > 1
      fn = "mul"; method_err(fn,x); return 0
    end  
    if y==3 # "a*b" in interaktive mode
       res1 = check_if_var(x.split[0])
       res2 = check_if_var(x.split[2])
       if (res1 == "nil" || res2 == "nil")
           fn = "plus"; method_err(fn,x); return 0
       end
       x = "print " + x 
       y = 4
    end
  
    if y==4 && !(x.includes?("="))  # fun() x + y 
       lside = x.split[0]
       rside = x.split[1..].join(" ")
       x = lside + " = " + rside
       y=5
    end
  
    if y == 5 # countera = counterb + 1
       lside, rside = x.split(" = ",remove_empty: true)
       p! rside, lside if VARS["debug"]
       rside_s = rside.split(" ",remove_empty: true)
       #if "a = a + 1"
       rside_s.insert(2,"=")
       rside_j = (rside_s.join(" "))
       if lside == rside_s[0]
        x = rside_j # rewrite "counter = counter + 1" to "counter + = 1"
        y = 4
       else  # numeric int only !
        #rside_res = rside_s[0].to_i + rside_s[3].to_i
        val1 = check_if_var(rside_s[0])
        val2 = check_if_var(rside_s[3])
        if (val1 == "nil" || val2 == "nil")
          fn = "plus"; method_err(fn,x); return 0
        end
        rside_res = val1.to_i * val2.to_i
        if KWS.has_key?(lside)                # do we have a function on left side ?
          KWS[lside].call(rside_res.to_s,1)   # give result as string
          return 0
        end  
        Code.vars_int32[lside] = rside_res    # store result in var
        p! rside_res if VARS["debug"]
        return 0
       end
       p! rside_s,rside_j,rside_res if VARS["debug"]
       #return 0
    end 
    if y == 4 # counter + = 3  
      varname = x.split(" ")[0]
      value = x.split(" ")[3].to_i
      if Code.vars_int32.has_key?(varname)
        Code.vars_int32[varname] += value
      end  
    else
      fn = "mul"
      method_err(fn,x) 
    end
    return 0
  end
  
  # div value from a var
  # example:  val/= 3
  # splitted: val / = 3
  def div(x : String, y : Int32)
    p! x if VARS["debug"] 
    occ = x.count("/")
    if occ > 1
      fn = "div"; method_err(fn,x); return 0
    end  
    if y==3 # "a+b" in interaktive mode
       res1 = check_if_var(x.split[0])
       res2 = check_if_var(x.split[2])
       if (res1 == "nil" || res2 == "nil")
           fn = "plus"; method_err(fn,x); return 0
       end
       x = "print " + x 
       y = 4
    end
  
    if y==4 && !(x.includes?("="))  # fun() x + y 
       lside = x.split[0]
       rside = x.split[1..].join(" ")
       x = lside + " = " + rside
       y=5
    end
  
    if y == 5 # countera = counterb + 1
       lside, rside = x.split(" = ",remove_empty: true)
       p! rside, lside if VARS["debug"]
       rside_s = rside.split(" ",remove_empty: true)
       #if "a = a + 1"
       rside_s.insert(2,"=")
       rside_j = (rside_s.join(" "))
       if lside == rside_s[0]
        x = rside_j # rewrite "counter = counter + 1" to "counter + = 1"
        y = 4
       else  # numeric int only !
        #rside_res = rside_s[0].to_i + rside_s[3].to_i
        val1 = check_if_var(rside_s[0])
        val2 = check_if_var(rside_s[3])
        if (val1 == "nil" || val2 == "nil")
          fn = "div"; method_err(fn,x); return 0
        end
        rside_res = (val1.to_i / val2.to_i).to_i
        if KWS.has_key?(lside)                # do we have a function on left side ?
          KWS[lside].call(rside_res.to_s,1)   # give result as string
          return 0
        end  
        Code.vars_int32[lside] = rside_res    # store result in var
        p! rside_res if VARS["debug"]
        return 0
       end
       p! rside_s,rside_j,rside_res if VARS["debug"]
       #return 0
    end 
    if y == 4 # counter + = 3  
      varname = x.split(" ")[0]
      value = x.split(" ")[3].to_i
      if Code.vars_int32.has_key?(varname)
        Code.vars_int32[varname] = (Code.vars_int32[varname] / value).to_i
      end  
    else
      fn = "div"
      method_err(fn,x) 
    end
    return 0
  end
  
  # increment var value 
  def inc(x : String, y : Int32)
    if y == 1 
      Code.vars_int32[x] += 1 #no split needed
    else
      fn = "inc"
      method_err(fn,x) 
    end
    return "",0
  end
  
  # decrement var value 
  def dec(x : String, y : Int32)
    if y == 1
      Code.vars_int32[x] -= 1 #no split needed
    else
      fn = "dec"
      method_err(fn,x) 
    end
    return "",0
  end
  