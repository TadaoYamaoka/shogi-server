$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require 'test/unit'
require 'shogi_server/buoy'
require 'mock_game'
require 'mock_player'
require 'mock_log_message'


class TestBuoyGame < Test::Unit::TestCase
  def test_equal
    g1 = ShogiServer::BuoyGame.new("buoy_1234-900-0", [], "p1", 1)
    g2 = ShogiServer::BuoyGame.new("buoy_1234-900-0", [], "p1", 1)
    assert_equal g1, g2
  end

  def test_not_equal
    g1 = ShogiServer::BuoyGame.new("buoy_1234-900-0", [], "p1", 1)
    g2 = ShogiServer::BuoyGame.new("buoy_1234-900-0", [], "p1", 2)
    assert_not_equal g1, g2
  end
end


class TestBuoy < Test::Unit::TestCase
  def setup
    @dir = File.dirname(__FILE__)
    @filename = File.join(@dir, "buoy.yaml")
    @conf = {:topdir => @dir}
    @buoy = ShogiServer::Buoy.new @conf
  end
  
  def teardown
    if File.exist? @filename
      File.delete @filename
    end
  end

  def test_game_name
    assert(ShogiServer::Buoy.game_name?("buoy_hoge-1500-0"))
    assert(ShogiServer::Buoy.game_name?("buoy_hoge-900-0"))
    assert(ShogiServer::Buoy.game_name?("buoy_hoge-0-30"))
    assert(!ShogiServer::Buoy.game_name?("buoyhoge-1500-0"))
    assert(!ShogiServer::Buoy.game_name?("hoge-1500-0"))
  end 

  def test_is_new_game1
    assert @buoy.is_new_game?("buoy_123-900-0")
  end

  def test_add_game
    game = ShogiServer::BuoyGame.new("buoy_1234-900-0", [], "p1", 1)
    @buoy.add_game(game)
    assert !@buoy.is_new_game?("buoy_1234-900-0")
    game2 = @buoy.get_game(game.game_name)
    assert_equal game, game2

    @buoy.delete_game game
    assert @buoy.is_new_game?("buoy_1234-900-0")
  end

  def test_update_game
    game = ShogiServer::BuoyGame.new("buoy_1234-900-0", [], "p1", 2)
    @buoy.add_game(game)
    g2 = ShogiServer::BuoyGame.new(game.game_name, game.moves, game.owner, game.count-1)
    @buoy.update_game(g2)
    
    get = @buoy.get_game(g2.game_name)
    assert_equal g2, get
  end
end

