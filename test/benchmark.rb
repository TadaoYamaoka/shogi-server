#!/usr/bin/ruby

require 'logger'
require 'socket'
require 'thread'

$logger = nil

class BenchPlayer
  def initialize(game_name, name, sente)
    @game_name = game_name
    @name = "%s_%s" % [game_name, name]
    @turn_mark = sente ? "+" : "-"
    @nmoves = 0
    @socket = nil
  end
  attr_reader :nmoves

  def connect
    port = 4000
    @socket = TCPSocket.open("localhost", port)
    @socket.sync = true
    @message = ""
    reader
  end

  def reader
    Thread.new do
      Thread.pass
      loop do 
        if r = select([@socket], nil, nil, 300)
          str = r[0].first.gets
          if %r!^[\+\-]\d{4}\w{2},T\d+$! =~ str
            @nmoves += 1
          end
          @message << str if str
        else
          $logger.warn "Timed out: %s" % [@name]
        end
      end
      $logger.error "Socket error: %s" % [@name]
    end
  end

  def wait(reg)
    loop do 
      break if reg =~ @message
      #$logger.debug "WAIT %s: %s" % [reg, @message]
      sleep 0.001
      #Thread.pass
    end
  end

  def wait_nmoves(n)
    loop do
      break if @nmoves == n
      sleep 0.001
      #Thread.pass
    end
  end

  def login
    @socket.puts "LOGIN #{@name} dummy x1"
    wait %r!^##\[LOGIN\] \+OK!
  end

  def game
    @socket.puts "%%GAME #{@game_name}-1500-0 #{@turn_mark}"
  end

  def agree
    @socket.puts "AGREE"
  end

  def move(m)
    @socket.puts m
  end

  def toryo
    @socket.puts "%TORYO"
  end

  def logout
    @socket.puts "LOGOUT"
  end

end

class BenchGame
  @@mutex = Mutex.new
  @@count = 0
  def initialize(game_name, csa)
    @game_name = game_name
    @csa = csa
    @@mutex.synchronize do 
      @p1 = BenchPlayer.new(@game_name, "bp#{@@count+=1}", true)
      @p2 = BenchPlayer.new(@game_name, "bp#{@@count+=1}", false)
    end
  end

  def each_player
    [@p1, @p2].each {|player| yield player}
  end

  def start
    $logger.info "Starting... %s" % [@game_name]
    $logger.debug "Connecting... %s" % [@game_name]
    each_player {|player| player.connect}
    $logger.debug "Logging in... %s" % [@game_name]
    each_player {|player| player.login}
    $logger.debug "Sending GAME... %s" % [@game_name]
    each_player {|player| player.game}
    $logger.debug "Waiting... %s" % [@game_name]
    each_player {|player| player.wait %r!^END Game_Summary!}
    $logger.debug "Agreeing... %s" % [@game_name]
    each_player {|player| player.agree}
    $logger.debug "AGREE waiting... %s" % [@game_name]
    each_player {|player| player.wait %r!^START:!}
    $logger.info "Started %s" % [@game_name]
    turn = true # black
    nmoves = 0
    @csa.each_line do |line|
      case line
      when /^\+\d{4}\w{2}/
        @p1.wait_nmoves nmoves
        @p1.move $&
        turn = false
        nmoves += 1
      when /^\-\d{4}\w{2}/
        @p2.wait_nmoves nmoves
        @p2.move $&
        turn = true
        nmoves += 1
      when /^%TORYO/
        $logger.debug "Waiting TORYO... %s" % [@game_name]
        @p1.wait_nmoves nmoves
        @p2.wait_nmoves nmoves
        turn ? @p1.toryo : @p2.toryo
      end
    end
    $logger.info "Logging out... %s" % [@game_name]
    each_player {|player| player.logout}
    $logger.info "Finished %s" % [@game_name]
  end
end


if __FILE__ == $0
  filepath = ARGV.shift || File.join(File.dirname(__FILE__), "csa", "wdoor+floodgate-900-0+gps_normal+gps_l+20100507120007.csa")
  csa = File.open(filepath){|f| f.read} 

  $logger = Logger.new(STDOUT)
  $logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO  

  nclients = ARGV.shift || 1
  nclients = nclients.to_i
  threads = []
  nclients.times do |i|
    threads << Thread.new do
      Thread.pass
      game = BenchGame.new("b#{i}", csa)
      game.start
    end
  end
  threads.each {|t| t.join}

end

