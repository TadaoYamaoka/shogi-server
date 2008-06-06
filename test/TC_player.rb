$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/player'

class TestPlayer < Test::Unit::TestCase
  def setup
    @p = ShogiServer::BasicPlayer.new
  end

  def test_without_password
    @p.name = "hoge"
    @p.set_password(nil)
    assert_nil(@p.player_id)
  end
  
  def test_set_password
    @p.name = "hoge"
    @p.set_password("abc")
    assert(@p.player_id)
  end

  def test_name_atmark
    @p.name = "hoge@p1"
    @p.set_password("abc")
    assert_match(/@/, @p.player_id)
  end

  def test_rating_group
    assert_nothing_raised {@p.rating_group = 1}
  end
end

