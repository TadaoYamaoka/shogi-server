$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/player'
require 'shogi_server/pairing'
require 'shogi_server/league/floodgate'

class MockLogger
  def debug(str)
  end
  def info(str)
    #puts str
  end
  def warn(str)
  end
  def error(str)
  end
end

$logger = MockLogger.new
def log_message(msg)
  $logger.info(msg)
end

def log_warning(msg)
  $logger.warn(msg)
end

class TestFloodgate < Test::Unit::TestCase
  def setup
    @fg = ShogiServer::League::Floodgate.new(nil)
  end

  def teardown

  end

  def test_game_name
    assert(ShogiServer::League::Floodgate.game_name?("floodgate-900-0"))
    assert(ShogiServer::League::Floodgate.game_name?("floodgate-0-10"))
    assert(!ShogiServer::League::Floodgate.game_name?("floodgat-900-0"))
  end

end

class TestPairing < Test::Unit::TestCase  
  def setup
    @pairing= ShogiServer::Pairing.new
    $pairs = []
    def @pairing.start_game(p1,p2)
      $pairs << [p1,p2]
    end
    @a = ShogiServer::BasicPlayer.new
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 0
    @a.last_game_win = false
    @b = ShogiServer::BasicPlayer.new
    @b.name = "b"
    @b.win  = 10
    @b.loss = 20
    @b.rate = 1500
    @b.last_game_win = true
    @c = ShogiServer::BasicPlayer.new
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
    @c.rate = 1000
    @c.last_game_win = true
    @d = ShogiServer::BasicPlayer.new
    @d.name = "d"
    @d.win  = 1000
    @d.loss = 2000
    @d.rate = 1800
    @d.last_game_win = true
  end

  def test_include_newbie
    assert(@pairing.include_newbie?([@a]))
    assert(!@pairing.include_newbie?([@b]))
    assert(@pairing.include_newbie?([@b,@a]))
    assert(!@pairing.include_newbie?([@b,@c]))
  end
end

class TestStartGame < Test::Unit::TestCase
  def setup
    @pairing= ShogiServer::StartGame.new
    $called = 0
    def @pairing.start_game(p1,p2)
      $called += 1
    end
    @a = ShogiServer::BasicPlayer.new
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 0
    @b = ShogiServer::BasicPlayer.new
    @b.name = "b"
    @b.win  = 10
    @b.loss = 20
    @b.rate = 1500
    @c = ShogiServer::BasicPlayer.new
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
    @c.rate = 1000
    @d = ShogiServer::BasicPlayer.new
    @d.name = "d"
    @d.win  = 1000
    @d.loss = 2000
    @d.rate = 2000
  end

  def test_match_two_players
    players = [@a,@b]
    @pairing.match(players)
    assert_equal(1, $called)
  end

  def test_match_one_player
    players = [@a]
    @pairing.match(players)
    assert_equal(0, $called)
  end

  def test_match_zero_player
    players = []
    @pairing.match(players)
    assert_equal(0, $called)
  end

  def test_match_three_players
    players = [@a,@b,@c]
    @pairing.match(players)
    assert_equal(1, $called)
  end

  def test_match_four_players
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $called)
  end
end

class TestDeleteMostPlayingPlayer < Test::Unit::TestCase
  def setup
    @pairing= ShogiServer::DeleteMostPlayingPlayer.new
    @a = ShogiServer::BasicPlayer.new
    @a.win  = 1
    @a.loss = 2
    @a.rate = 0
    @b = ShogiServer::BasicPlayer.new
    @b.win  = 10
    @b.loss = 20
    @b.rate = 1500
    @c = ShogiServer::BasicPlayer.new
    @c.win  = 100
    @c.loss = 200
    @c.rate = 1000
  end

  def test_match
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal([@a,@b], players)
  end
end

class TestLeastRatePlayer < Test::Unit::TestCase  
  def setup
    @pairing= ShogiServer::DeleteLeastRatePlayer.new
    @a = ShogiServer::BasicPlayer.new
    @a.win  = 1
    @a.loss = 2
    @a.rate = 0
    @b = ShogiServer::BasicPlayer.new
    @b.win  = 10
    @b.loss = 20
    @b.rate = 1500
    @c = ShogiServer::BasicPlayer.new
    @c.win  = 100
    @c.loss = 200
    @c.rate = 1000
  end

 def test_match
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal([@b,@c], players)
  end
end

class TestRandomize < Test::Unit::TestCase  
  def setup
    srand(10) # makes the random number generator determistic
    @pairing = ShogiServer::Randomize.new
    @a = ShogiServer::BasicPlayer.new
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @b = ShogiServer::BasicPlayer.new
    @b.name = "b"
    @b.win  = 10
    @b.loss = 20
    @c = ShogiServer::BasicPlayer.new
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
  end

  def test_match
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal([@b,@a,@c], players)
  end
end

class TestSortByRate < Test::Unit::TestCase  
  def setup
    @pairing = ShogiServer::SortByRate.new
    @a = ShogiServer::BasicPlayer.new
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 1500
    @b = ShogiServer::BasicPlayer.new
    @b.name = "b"
    @b.win  = 10
    @b.loss = 20
    @b.rate = 2000
    @c = ShogiServer::BasicPlayer.new
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
    @c.rate = 700
  end

  def test_match
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal([@c,@a,@b], players)
  end
end

class TestSortByRateWithRandomness < Test::Unit::TestCase  
  def setup
    srand(10) # makes the random number generator determistic
    @pairing = ShogiServer::SortByRateWithRandomness.new(1200, 2400)
    @a = ShogiServer::BasicPlayer.new
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 1500
    @b = ShogiServer::BasicPlayer.new
    @b.name = "b"
    @b.win  = 10
    @b.loss = 20
    @b.rate = 2000
    @c = ShogiServer::BasicPlayer.new
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
    @c.rate = 700
  end

  def test_match
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal([@c,@b,@a], players)
  end
end

class TestExcludeSacrifice < Test::Unit::TestCase  
  def setup
    @obj = ShogiServer::ExcludeSacrificeGps500.new
    @a = ShogiServer::BasicPlayer.new
    @a.player_id   = "a"
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 0
    @a.last_game_win = false
    @b = ShogiServer::BasicPlayer.new
    @b.player_id   = "gps500+e293220e3f8a3e59f79f6b0efffaa931"
    @b.name = "gps500"
    @b.win  = 10
    @b.loss = 20
    @b.rate = 1500
    @b.last_game_win = true
    @c = ShogiServer::BasicPlayer.new
    @c.player_id   = "c"
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
    @c.rate = 1000
    @c.last_game_win = true
  end

  def test_match_1
    players = [@a]
    @obj.match(players)
    assert_equal([@a], players)
  end
  
  def test_match_2
    players = [@b]
    @obj.match(players)
    assert_equal([], players)
  end
  
  def test_match_3
    players = [@a, @b]
    @obj.match(players)
    assert_equal([@a,@b], players)
  end

  def test_match_4
    players = [@a, @b, @c]
    @obj.match(players)
    assert_equal([@a, @c], players)
  end

  def test_match_5
    players = [@a, @c]
    @obj.match(players)
    assert_equal([@a,@c], players)
  end
end

