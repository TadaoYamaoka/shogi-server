$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/player'
require 'shogi_server/pairing'
require 'shogi_server/league/floodgate'
require 'test/mock_log_message'

$topdir = File.expand_path File.dirname(__FILE__)

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

  def test_instance_game_name
    fg = ShogiServer::League::Floodgate.new(nil, {:game_name => "floodgate-900-0"})
    assert(fg.game_name?("floodgate-900-0"))
    assert(!fg.game_name?("floodgate-3600-0"))
    fg = ShogiServer::League::Floodgate.new(nil, {:game_name => "floodgate-3600-0"})
    assert(!fg.game_name?("floodgate-900-0"))
    assert(fg.game_name?("floodgate-3600-0"))
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

class TestMakeEven < Test::Unit::TestCase  
  def setup
    srand(10)
    @pairing= ShogiServer::MakeEven.new
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
  end

 def test_match_even
    players = [@a, @b]
    @pairing.match(players)
    assert_equal([@a,@b], players)
 end

 def test_match_odd
    players = [@a, @b, @c]
    @pairing.match(players)
    assert_equal(2, players.size)
    assert(players[0] != players[1])
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
    assert_equal(3, players.size)
    assert(players.include? @a)
    assert(players.include? @b)
    assert(players.include? @c)
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

class TestSwissPairing < Test::Unit::TestCase
  def setup
    srand(10)
    @a = ShogiServer::BasicPlayer.new
    @a.player_id = "a"
    @a.rate = 0
    @a.game_name = "floodgate-900-0"
    @b = ShogiServer::BasicPlayer.new
    @b.player_id = "b"
    @b.rate = 1000
    @b.game_name = "floodgate-900-0"
    @c = ShogiServer::BasicPlayer.new
    @c.player_id = "c"
    @c.rate = 1500
    @c.game_name = "floodgate-900-0"
    @d = ShogiServer::BasicPlayer.new
    @d.player_id = "d"
    @d.rate = 2000
    @d.game_name = "floodgate-900-0"

    @players = [@a, @b, @c, @d]

    @file = Pathname.new(File.join(File.dirname(__FILE__), "floodgate_history_900_0.yaml"))
    @history = ShogiServer::League::Floodgate::History.factory @file

    @swiss = ShogiServer::Swiss.new
  end

  def teardown
    @file.delete if @file.exist?
  end

  def test_none
    players = []
    @swiss.match players
    assert(players.empty?)
  end

  def test_all_win
    ShogiServer::League::Floodgate::History.class_eval do
      def last_win?(player_id)
        true
      end
    end
    @swiss.match @players
    assert_equal([@d, @c, @b, @a], @players)
  end

  def test_all_lose
    ShogiServer::League::Floodgate::History.class_eval do
      def last_win?(player_id)
        false
      end
    end
    @swiss.match @players
    assert_equal([@d, @c, @b, @a], @players)
  end

  def test_one_win
    ShogiServer::League::Floodgate::History.class_eval do
      def last_win?(player_id)
        if player_id == "a"
          true
        else
          false
        end
      end
    end
    @swiss.match @players
    assert_equal([@a, @d, @c, @b], @players)
  end

  def test_two_win
    ShogiServer::League::Floodgate::History.class_eval do
      def last_win?(player_id)
        if player_id == "a" || player_id == "d"
          true
        else
          false
        end
      end
    end
    @swiss.match @players
    assert_equal([@d, @a, @c, @b], @players)
  end
end

class TestFloodgateHistory < Test::Unit::TestCase
  def setup
    @file = Pathname.new(File.join(File.dirname(__FILE__), "floodgate_history.yaml"))
    @history = ShogiServer::League::Floodgate::History.new @file
  end

  def teardown
    @file.delete if @file.exist?
  end

  def test_new
    file = Pathname.new(File.join(File.dirname(__FILE__), "hoge.yaml"))
    history = ShogiServer::League::Floodgate::History.new file
    history.save
    assert file.exist?
    file.delete if file.exist?
  end

  def test_update
    dummy = nil
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-hoge-foo-1", 
       :black => "hoge",  :white => "foo",
       :winner => "foo", :loser => "hoge"}
    end
    @history.update(dummy)

    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-hoge-foo-2", 
       :black => "hoge",  :white => "foo",
       :winner => "hoge", :loser => "foo"}
    end
    @history.update(dummy)

    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-hoge-foo-3", 
       :black => "hoge",  :white => "foo",
       :winner => nil, :loser => nil}
    end
    @history.update(dummy)

    @history.load
    assert_equal 3, @history.records.size
    assert_equal "wdoor+floodgate-900-0-hoge-foo-1", @history.records[0][:game_id]
    assert_equal "wdoor+floodgate-900-0-hoge-foo-2", @history.records[1][:game_id]
    assert_equal "wdoor+floodgate-900-0-hoge-foo-3", @history.records[2][:game_id]
    assert_equal "hoge", @history.records[1][:black]
    assert_equal "foo",  @history.records[1][:white]
    assert_equal "hoge", @history.records[1][:winner]
    assert_equal "foo",  @history.records[1][:loser]

    assert @history.last_win? "hoge"
    assert !@history.last_win?("foo")
    assert !@history.last_lose?("hoge")
    assert @history.last_lose?("foo")

    assert_equal("foo", @history.last_opponent("hoge"))
    assert_equal("hoge", @history.last_opponent("foo"))

    games = @history.win_games("hoge")
    assert_equal(1, games.size )
    assert_equal("wdoor+floodgate-900-0-hoge-foo-2", games[0][:game_id])
    games = @history.win_games("foo")
    assert_equal(1, games.size )
    assert_equal("wdoor+floodgate-900-0-hoge-foo-1", games[0][:game_id])
    games = @history.loss_games("hoge")
    assert_equal(1, games.size )
    assert_equal("wdoor+floodgate-900-0-hoge-foo-1", games[0][:game_id])
    games = @history.loss_games("foo")
    assert_equal(1, games.size )
    assert_equal("wdoor+floodgate-900-0-hoge-foo-2", games[0][:game_id])
  end
end


