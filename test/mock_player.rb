$:.unshift File.join(File.dirname(__FILE__), "..")
require 'shogi_server/player'

class MockPlayer < ShogiServer::BasicPlayer
  attr_reader :out
  attr_accessor :game, :status, :protocol
  attr_accessor :game_name
  attr_reader :socket_buffer

  def initialize
    @name     = "mock_player"
    @out      = []
    @game     = nil
    @status   = nil
    @protocol = nil
    @game_name = "dummy_game_name"
    @socket_buffer = []
  end

  def write_safe(str)
    @out << str
  end
end


