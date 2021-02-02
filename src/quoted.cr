#test the quoted functions
def quoted_test()
s1 = %Q[counter+=1]
s2 = %Q[counter+= 1; print "12+3"]
s3 = %Q[counter+= 1; print "12+3"; i+=1 ]
s4 = %Q[counter+= 1; print '+'; i+=1 ]

line = split_operator_from_var(s1,"+")
puts line
line = split_operator_from_var(s2,"+")
puts line
line = split_operator_from_var(s3,"+")
puts line
line = split_operator_from_var(s4,"+")
puts line
end
#quoted_test()

#split operator of type String by blank
def split_operator_from_var(line,operator)
    offs = 0
    res_line=line
    nres = 0
    i = line.index(operator,offs)
    while i  
     i = line.index(operator,offs)
     #p! i 
     if i
       q = inside_quotes?('"',line,i) || inside_quotes?("'",line,i) 
       if !q
         res_line = res_line.insert(i+nres," ") 
         res_line = res_line.insert(i+nres+2," ") if res_line
         nres+=2
         #p! res_line
       end
     end  
     offs = i + 1 if i 
    end
    return res_line
end    

#check if a char in a line is quoted
#argument char defines the quotes used
#e.g. " or ' or any other char
def inside_quotes?(char,line,pos)
   offs = 0
   qpos = line.index(char)  # find first opening quote
   qflag = true
   while qpos
      qpos2 = line.index(char,offs) # find closing quotes
      qflag = !qflag 
      if qpos2
       return qflag if qpos2 > pos # found closing quotes
      end
      offs = qpos + 1 if qpos
      qpos = qpos2
     end
end     

def unquote(x : String)
  if VARS["debug"]
   puts "unquote()"
   p! x 
  end
  return x,1 if x.size < 3
  if (x[0] == '"' && x[-1] == '"') #quotes ?
     x=x.gsub('"',"")   # remove ""
     x=x.gsub('_',' ')  # underscore -> blank
     p! x if VARS["debug"]
     return x,0
  else
     puts "nothing to unquoute" if VARS["debug"]
     return x,1 
  end   
end  
