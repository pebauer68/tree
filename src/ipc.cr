# run cmd as a long running sub process in a fiber
def run_long_cmd(proc_stdin, proc_stdout)
  spawn do # spawn a process, e.g. a bash shell
    args = ["-i"]
    Process.run("bash", shell: true, args: nil, output: proc_stdout, input: proc_stdin)
    puts "\rIPC Process ended"
  end
end

#open_IPC()
def open_ipc
  reader, writer = IO.pipe   # writer goes to process input
  reader2, writer2 = IO.pipe # reader2 goes to terminal stdout
  run_long_cmd(reader, writer2)
  writer << "exec ruby ipc2.rb\n"
  # writer << "pypy3 echo1.py\n"
  p! writer
  p! reader
  Code.writer = writer
  Code.reader = reader2
end

#send_ipc()
def send_ipc(line)
  p! line if Code.debug
  line = line[1..-2]  # remove quotes
  fd = Code.writer
  fd << line << "\n"
  fd.flush
  # print "sending: ",Time.local.to_s("%H:%M:%S.%6N"),"\n"
  # print ">> ",line,"\n"
end

#receive_ipc()
def receive_ipc
  res = Code.reader.gets
  # print "<< ",IPCIN.to_s,"\n"
  # print "receive: ",Time.local.to_s("%H:%M:%S.%6N"),"\n"
  # return IPC_read.read, 0
  return res,0
end

class IPC_read
  def initialize
    @res = Code.reader 
    puts "IPC initialized"
  end
  
  def read
      return @res.try &.gets
  end
end  

def send_receive_ipc(line)
  p! line if Code.debug
  if line.starts_with?("\"")
    line = line[1..-2] # remove quotes on start and end
  end
  fd = VARS["writer"].as(IO::FileDescriptor)
  fd << line << "\n"
  fd.flush
  res = VARS["reader"].as(IO::FileDescriptor).gets
  return res, 0
  # print "sending: ",Time.local.to_s("%H:%M:%S.%6N"),"\n"
  # print ">> ",line,"\n"
end

# show_ipc_results()
# get ipc read result from ipc connection
# write result to stdout
def show_ipc_results(x)
  !puts x if Code.debug

  count = 0
  IPCIN.each { |line|
    # STDOUT << "Count: #{count} \n #{line} \n" #slower !
    print "Count: ", count, "\n", line, "\n"
    count += 1
  }
  IPCIN.clear if x.includes?("clear")
end
