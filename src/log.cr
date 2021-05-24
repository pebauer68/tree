require "log"
# log to a file
# example output line: 
# 2021-04-24 09:00:53.648818  INFO  log cleared
class Mylog
    Log = ::Log.for("tree", :debug)
    
    #p! Log
    # => #<Log:0x7fe6e190f500 @source="tree",
    # @backend=#<Log::IOBackend:0x7fe6e190f600 
    # @dispatcher=#<Log::AsyncDispatcher:0x7fe6e190cd40 
    # @channel=#<Channel(Tuple(Log::Entry, Log::Backend)):0x7fe6e190f5c0>, 
    # @done=#<Channel(Nil):0x7fe6e190f580>>, 
    # @io=#<IO::FileDescriptor: fd=3>, 
    # @formatter=Log::ShortFormat>, 
    # @level=Debug, 
    # @initial_level=Info>

    def initialize
      return if ! Code.log
      @file_name = "./tree.log"  
      @backend = ::Log::IOBackend.new(fhandle=File.new(@file_name, "a"))
      @backend.formatter = ::Log::Formatter.new do |entry, io|
        io << entry.timestamp.to_s("%Y-%m-%d %H:%M:%S.%6N  ") 
        io << entry.severity.label << "  "
        io << entry.message
      end
      Log.backend = @backend
      print "Log init,logging to file: ",@file_name,"\n"
    end

    #clearlog()
    def clearlog
      @backend.close if @backend
      File.delete(@file_name) if File.exists?(@file_name)
      initialize
      self.info("log cleared")
    end

    def info(msg)
      Log.info { msg  }  
    end  

    def error(msg)
      Log.error { msg }
    end

end    

Tlog = Mylog.new         # use constant for global visibility
if Code.log
  Tlog.info "tree started" 
end