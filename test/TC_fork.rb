$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require "baseclient"
require "shogi_server/buoy.rb"

class TestFork < BaseClient
  def parse_game_name(player)
    player.puts "%%LIST"
    sleep 1
    if /##\[LIST\] (.*)/ =~ player.message
      return $1
    end
  end

  def test_wrong_game
    @admin = SocketPlayer.new "dummy", "admin", false
    @admin.connect
    @admin.reader
    @admin.login

    result, result2 = handshake do
      @admin.puts "%%FORK wronggame-900-0 buoy_WrongGame-900-0"
      sleep 1
    end

    assert /##\[ERROR\] wrong source game name/ =~ @admin.message
    @admin.logout
  end

  def test_too_short_fork
    @admin = SocketPlayer.new "dummy", "admin", false
    @admin.connect
    @admin.reader
    @admin.login

    result, result2 = handshake do
      source_game = parse_game_name(@admin)
      @admin.puts "%%FORK #{source_game} buoy_TooShortFork-900-0 0"
      sleep 1
    end

    assert /##\[ERROR\] number of moves to fork is out of range/ =~ @admin.message
    @admin.logout
  end

  def test_fork
    buoy = ShogiServer::Buoy.new
    
    @admin = SocketPlayer.new "dummy", "admin", "*"
    @admin.connect
    @admin.reader
    @admin.login
    assert buoy.is_new_game?("buoy_Fork-1500-0")

    result, result2 = handshake do
      source_game = parse_game_name(@admin)
      @admin.puts "%%FORK #{source_game} buoy_Fork-1500-0"
      sleep 1
    end

    assert buoy.is_new_game?("buoy_Fork-1500-0")
    @p1 = SocketPlayer.new "buoy_Fork", "p1", true
    @p2 = SocketPlayer.new "buoy_Fork", "p2", false
    @p1.connect
    @p2.connect
    @p1.reader
    @p2.reader
    @p1.login
    @p2.login
    sleep 1
    @p1.game
    @p2.game
    sleep 1
    @p1.agree
    @p2.agree
    sleep 1
    assert /^Total_Time:1500/ =~ @p1.message
    assert /^Total_Time:1500/ =~ @p2.message
    @p2.move("-3334FU")
    sleep 1
    @p1.toryo
    sleep 1
    @p2.logout
    @p1.logout

    @admin.logout
  end
end
