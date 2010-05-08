#!/usr/bin/ruby

require 'socket'

class BenchPlayer
  def initialize(game_name, name, sente)
    @game_name = game_name
    @name = "%s_%s" % [game_name, name]
    @turn_mark = sente ? "+" : "-"
    @nmoves = 0
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
      loop do 
        if r = select([@socket], nil, nil, 10)
          str = r[0].first.gets
          if %r!^[\+\-]\d{4}\w{2},T\d+$! =~ str
            @nmoves += 1
          end
          @message << str
        else
          raise "timed out"
        end
      end
    end
  end

  def wait(reg)
    loop do 
      break if reg =~ @message
      sleep 0.1
    end
  end

  def wait_nmoves(n)
    loop do
      break if @nmoves == n
      sleep 0.01
    end
  end

  def login
    @socket.puts "LOGIN #{@name} dummy x1"
    wait %r!^LOGIN!
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
  def initialize(game_name, csa)
    @game_name = game_name
    @csa = csa
    @p1 = BenchPlayer.new(@game_name, "bp1", true)
    @p2 = BenchPlayer.new(@game_name, "bp2", false)
  end

  def each_player
    [@p1, @p2].each {|player| yield player}
  end

  def start
    each_player {|player| player.connect}
    each_player {|player| player.login}
    each_player {|player| player.game}
    each_player {|player| player.wait %r!^END Game_Summary!}
    each_player {|player| player.agree}
    each_player {|player| player.wait %r!^START:!}
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
        turn ? @p1.toryo : @p2.toryo
      end
    end
    each_player {|player| player.logout}
  end
end


if __FILE__ == $0
  filepath = ARGV.shift || File.join(File.dirname(__FILE__), "csa", "wdoor+floodgate-900-0+gps_normal+gps_l+20100507120007.csa")
  csa = File.open(filepath){|f| f.read} 

  nclients = ARGV.shift || 1
  nclients = nclients.to_i
  threads = []
  nclients.times do |i|
    threads << Thread.new do
      game = BenchGame.new("b#{i}", csa)
      game.start
    end
  end
  threads.each {|t| t.join}

end

