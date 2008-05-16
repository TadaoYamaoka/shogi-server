require 'socket'
require 'stringio'
require 'test/unit'

class BaseClient < Test::Unit::TestCase
  def setup
    port = 4000
    params = {"Host" => "localhost", "Port" => port, "Prompt" => //}
    @socket1 = TCPSocket.open("localhost", port)
    @socket2 = TCPSocket.open("localhost", port)
  end

  def teardown
    @socket1.close
    @socket2.close
  end

  def login
    classname = self.class.name
    cmd "LOGIN sente#{classname} dummy x1"
    cmd "%%GAME test#{classname}-1500-0 +"
    
    cmd2 "LOGIN gote#{classname} dummy2 x1"
    cmd2 "%%CHALLENGE test#{classname}-1500-0 -"
  end

  def agree
    cmd  "AGREE"
    sleep 0.5
    cmd2 "AGREE"
  end

  def handshake
    login

    sleep 2 # to wait for game matching

    agree

    cmd  "+2726FU"
    cmd2 "-3334FU"
   
    yield if block_given?
    sleep 2
    result  = cmd  "LOGOUT"
    result2 = cmd2 "LOGOUT"
    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)
    [result, result2]
  end

  def read_nonblock(io)
    sleep 0.05  
    str = ""
    begin
      loop do   
        str << io.read_nonblock(64)
      end
    rescue Errno::EAGAIN
      # do nothing
    rescue EOFError
      # do nothing
    end
    str
  end

  def cmd(s)
    # read the previous return
    str = read_nonblock(@socket1)
    @socket1.puts s if s && ! @socket1.closed?
    str
  end

  def cmd2(s)
    # read the previous return
    str = read_nonblock(@socket2)
    @socket2.puts s if s && ! @socket2.closed?
    str
  end

  def logout12
    cmd  "LOGOUT"
    cmd2 "LOGOUT"
    sleep 1
  end

  def logout21
    cmd2 "LOGOUT"
    cmd  "LOGOUT"
    sleep 1
  end

  def test_dummy
    assert true
  end
end


class ReadFileClient < BaseClient
  def filepath(csa_file_name)
    return File.join(File.dirname(__FILE__), "csa", csa_file_name)
  end

  def handshake(csa)
    login
    sleep 1
    agree
    sleep 1

    csa_io = StringIO.new(csa)
    while line = csa_io.gets do
      case line
      when /^\+\d{4}\w{2}/
        cmd $&
      when /^\-\d{4}\w{2}/
        cmd2 $&
      end
    end
  end
end # ReadFileClient
