$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/player'
require 'shogi_server/login'
require 'shogi_server/handicapped_boards'

class ShogiServer::BasicPlayer
  attr_accessor :protocol
end


class TestLogin < Test::Unit::TestCase 
  def setup
    @p_csa = ShogiServer::BasicPlayer.new
    @p_csa.name = "hoge"
    @p_x1 = ShogiServer::BasicPlayer.new
    @p_x1.name = "hoge"
    @csa = ShogiServer::LoginCSA.new(@p_csa,"floodgate-900-0,xyz")
    @x1 = ShogiServer::Loginx1.new(@p_x1, "xyz")
  end

  def test_player_id
    assert(@p_x1.player_id == @p_csa.player_id)
  end

  def test_login_factory_x1
    player = ShogiServer::BasicPlayer.new
    player.name = "hoge"
    login = ShogiServer::Login::factory("LOGIN hoge xyz x1", player)
    assert_equal(@p_x1.player_id, player.player_id)
  end

  def test_login_factory_csa
    player = ShogiServer::BasicPlayer.new
    player.name = "hoge"
    login = ShogiServer::Login::factory("LOGIN hoge floodagate-900-0,xyz", player)
    assert_equal(@p_csa.player_id, player.player_id)
  end
end

