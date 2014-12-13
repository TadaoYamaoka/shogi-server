require 'socket'
require 'stringio'
require 'thread'
require 'test/unit'

class SocketPlayer
  def initialize(game_name, name, sente)
    @game_name = game_name
    @name = "%s_%s" % [game_name, name]
    if sente == "*"
      @turn_mark = sente
    else
      @turn_mark = sente ? "+" : "-"
    end
    @received_moves = 0
    @socket = nil
    @message = ""
    @mutex = Mutex.new
    @login_command = "LOGIN #{@name} dummy x1"
  end
  attr_reader :message
  attr_accessor :login_command

  def connect
    port = 4000
    @socket = TCPSocket.open("localhost", port)
    @socket.sync = true
    @message = ""
    reader
  end

  def close
    @socket.close if @socket && !@socket.closed?
  end

  def reader
    @thread = Thread.new do
      begin
        Thread.pass
        loop do 
          break if @socket.closed?
          if r = select([@socket], nil, nil, 10)
            str = r[0].first.gets
            break if str.nil?
            @mutex.synchronize do
              if %r!^[\+\-]\d{4}\w{2},T\d+$! =~ str
                  @received_moves += 1
              end
              @message << str
            end
          else
            raise "timed out"
          end
        end
      rescue IOError
        $stderr.puts "\nReader thread interrupted"
      end
    end
  end

  def stop_reader
    @thread.kill if @thread
  end

  def wait(reg)
    loop do 
      @mutex.synchronize do
        return if reg =~ @message
      end
      sleep 0.01
    end
  end

  def wait_nmoves(n)
    loop do
      @mutex.synchronize do
        return if @received_moves == n
      end
      sleep 0.01
    end
  end

  def login
    str = @login_command
    $stderr.puts str if $DEBUG
    @socket.puts str
    wait %r!^LOGIN!
  end

  def game
    str = "%%GAME #{@game_name}-1500-0 #{@turn_mark}"
    $stderr.puts str if $DEBUG
    @socket.puts str
  end

  def challenge
    str = "%%CHALLENGE #{@game_name}-1500-0 #{@turn_mark}"
    $stderr.puts str if $DEBUG
    @socket.puts str
  end

  def wait_game
    wait %r!^END Game_Summary!
  end

  def agree
    @socket.puts "AGREE"
  end

  def wait_agree
    wait %r!^START:!
  end

  def move(m)
    @socket.puts m
  end
  def puts(m)
    @socket.puts m
  end

  def toryo
    @socket.puts "%TORYO"
  end

  def wait_finish
    wait %r!^#(WIN|LOSE)!
  end

  def logout
    @socket.puts "LOGOUT"
    @socket.close
  end

end

class SocketCSAPlayer < SocketPlayer
  def initialize(game_name, name, sente)
    super
    @login_command = "LOGIN #{@name} dummy"
  end

  def login
    str = @login_command
    $stderr.puts str if $DEBUG
    @socket.puts str
    wait %r!^LOGIN!
  end
end





class BaseClient < Test::Unit::TestCase
  attr_accessor :game_name, :p1_name, :p2_name

  def set_name
    @game_name = self.class.name
    @p1_name = "sente"
    @p2_name = "gote"
  end

  def set_player
    @p1 = SocketPlayer.new @game_name, @p1_name, true
    @p2 = SocketPlayer.new @game_name, @p2_name, false
  end

  def setup
    set_name
    set_player
    @nmoves = 0
  end
  attr_reader :src1, :src2

  def teardown
    @p1.close
    @p2.close
  end

  def test_dummy
    assert true
  end

  def login
    @p1.connect
    @p2.connect
    @p1.login
    @p2.login
    @p1.game
    @p2.game
    @p1.wait_game
    @p2.wait_game
  end

  def agree
    @p1.agree
    @p2.agree
    @p1.wait_agree
    @p2.wait_agree
  end

  def handshake
    login
    agree

    move "+2726FU"
    move "-3334FU"
   
    yield if block_given?

    logout12
    [@p1.message, @p2.message]
  end

  def move(m)
    case m
    when /^\+/
      move1(m)
    when /^\-/
      move2(m)
    else
      raise "do not reach!"
    end
  end

  def move1(m)
    @p1.move m
    @nmoves += 1
    @p2.wait_nmoves @nmoves
  end

  def move2(m)
    @p2.move m
    @nmoves += 1
    @p1.wait_nmoves @nmoves
  end

  def cmd(s)
    @p1.move s
    return @p1.message
  end

  def cmd2(s)
    @p2.move s
    return @p2.message
  end

  def wait_finish
    @p1.wait_finish
    @p2.wait_finish
  end

  def logout12
    @p1.logout
    @p2.logout
  end

  def logout21
    @p2.logout
    @p1.logout
  end

end


class ReadFileClient < BaseClient
  def filepath(csa_file_name)
    return File.join(File.dirname(__FILE__), "csa", csa_file_name)
  end

  def handshake(csa)
    login
    agree

    csa_io = StringIO.new(csa)
    while line = csa_io.gets do
      case line
      when /^[\+\-]\d{4}\w{2}/
        s = $&
        $stderr.puts s if $DEBUG
        move s
      end
    end
  end
end # ReadFileClient


class CSABaseClient < BaseClient
  ##
  # In CSA mode, the server decides sente or gote at random; and sockets are closed
  # just after the game ends (i.e. %TORYO is sent)
  # 
  def set_player
    @p1 = SocketCSAPlayer.new @game_name, @p1_name, true
    @p2 = SocketCSAPlayer.new @game_name, @p2_name, false
  end

  def teardown
    @p1.stop_reader
    @p2.stop_reader
    super
  end

  def handshake
    @p1.connect
    @p2.connect
    @p1.login
    @p2.login
    agree

    if /Your_Turn:\+/ =~ @p1.message
    else
      @p1,@p2 = @p2,@p1
    end

    move "+7776FU"
    move "-3334FU"
    yield if block_given?
    
    [@p1.message, @p2.message]
  end

end # CSABaseClient


