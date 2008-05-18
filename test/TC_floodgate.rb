$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
load 'shogi-server'
require 'pairing' 

class MockLogger
  def debug(str)
  end
  def info(str)
    # puts str
  end
  def warn(str)
  end
  def error(str)
  end
end

$logger = MockLogger.new

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

  def test_delete_most_playing_player
    players = [@a, @b, @c]
    @pairing.delete_most_playing_player(players)
    assert_equal([@a,@b], players)
  end

  def test_delete_least_rate_player
    players = [@a, @b, @c]
    @pairing.delete_least_rate_player(players)
    assert_equal([@b,@c], players)
  end
end

class TestRandomPairing < Test::Unit::TestCase  
  def setup
    @pairing= ShogiServer::RandomPairing.new
    $called = 0
    def @pairing.start_game(p1,p2)
      $called += 1
    end
    @a = ShogiServer::BasicPlayer.new
    @a.win  = 1
    @a.loss = 2
    @b = ShogiServer::BasicPlayer.new
    @b.win  = 10
    @b.loss = 20
    @c = ShogiServer::BasicPlayer.new
    @c.win  = 100
    @c.loss = 200
  end

  def test_random_match_1
    players = [@a]
    @pairing.match(players)
    assert_equal(0, $called)
  end

  def test_random_match_2
    players = [@a,@b]
    @pairing.match(players)
    assert_equal(1, $called)
  end
  
  def test_random_match_3
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal(1, $called)
  end
end

class TestSwissPairing < Test::Unit::TestCase  
  def setup
    @pairing= ShogiServer::SwissPairing.new
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

  def sort(players)
    return players.sort{|a,b| a.name <=> b.name}
  end

  def test_include_newbie
    assert(@pairing.include_newbie?([@a]))
    assert(!@pairing.include_newbie?([@b]))
    assert(@pairing.include_newbie?([@b,@a]))
    assert(!@pairing.include_newbie?([@b,@c]))
  end

  def test_match_1
    @pairing.match([@a])
    assert_equal(0, $pairs.size)
  end
  
  def test_match_2
    @pairing.match([@b])
    assert_equal(0, $pairs.size)
  end
  
  def test_match_3
    @pairing.match([@a,@b])
    assert_equal(1, $pairs.size)
    assert_equal(sort([@a,@b]), sort($pairs.first))
  end
  
  def test_match_4
    @pairing.match([@c,@b])
    assert_equal(1, $pairs.size)
    assert_equal(sort([@b,@c]), sort($pairs.first))
  end
  
  def test_match_5
    @pairing.match([@c,@b,@a])
    assert_equal(1, $pairs.size)
    assert_equal(sort([@b,@c]), sort($pairs.first))
  end
  
  def test_match_6
    @pairing.match([@c,@b,@a,@d])
    assert_equal(2, $pairs.size)
    assert_equal(sort([@b,@d]), sort($pairs.first))
    assert_equal(sort([@a,@c]), sort($pairs.last))
  end
end

class TestExcludeSacrifice < Test::Unit::TestCase  
  class Dummy
    attr_reader :players
    def match(players)
      @players = players
    end
  end
  
  def setup
    @dummy = Dummy.new
    @obj = ShogiServer::ExcludeSacrifice.new(@dummy)
    @a = ShogiServer::BasicPlayer.new
    @a.player_id   = "a"
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 0
    @a.last_game_win = false
    @b = ShogiServer::BasicPlayer.new
    @b.player_id   = "gps500+e293220e3f8a3e59f79f6b0efffaa931"
    @b.name = "b"
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
    @obj.match([@a])
    assert_equal(1, @dummy.players.size)
  end
  
  def test_match_2
    @obj.match([@b])
    assert_equal(0, @dummy.players.size)
  end
  
  def test_match_3
    @obj.match([@a, @b])
    assert_equal(2, @dummy.players.size)
  end

  def test_match_4
    @obj.match([@a, @b, @c])
    assert_equal(2, @dummy.players.size)
  end

  def test_match_5
    @obj.match([@a, @c])
    assert_equal(2, @dummy.players.size)
  end
end

