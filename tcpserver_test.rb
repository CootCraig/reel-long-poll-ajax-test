require 'socket'
tcps = ::TCPServer.new 8100
begin
  tcps.accept_nonblock
rescue Errno::EAGAIN => ex
  puts "accept_nonblock would block"
rescue => ex
  puts "exception other than Errno::EAGAIN #{ex.class} #{ex.message}"
end

