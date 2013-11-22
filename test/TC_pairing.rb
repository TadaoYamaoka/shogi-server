$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/league.rb'
require 'shogi_server/player'
require 'shogi_server/pairing'
require 'test/mock_log_message'

def same_pair?(a, b)
  unless a.size == 2 && b.size == 2
    return false
  end

  return true if [a.first, a.last] == b || [a.last, a.first] == b
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

class TestStartGameWithoutHumans < Test::Unit::TestCase
  def setup
    @pairing= ShogiServer::StartGameWithoutHumans.new
    $paired = []
    $called = 0
    def @pairing.start_game(p1,p2)
      $called += 1
      $paired << [p1,p2]
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
    @e = ShogiServer::BasicPlayer.new
    @e.name = "e"
    @e.win  = 3000
    @e.loss = 3000
    @e.rate = 3000
    @f = ShogiServer::BasicPlayer.new
    @f.name = "f"
    @f.win  = 4000
    @f.loss = 4000
    @f.rate = 4000
    @g = ShogiServer::BasicPlayer.new
    @g.name = "g"
    @g.win  = 5000
    @g.loss = 5000
    @g.rate = 5000
    @h = ShogiServer::BasicPlayer.new
    @h.name = "h"
    @h.win  = 6000
    @h.loss = 6000
    @h.rate = 6000
  end

  def test_match_one_player
    players = [@a]
    @pairing.match(players)
    assert_equal(0, $called)
  end

  def test_match_one_player_human
    @a.name += "_human"
    players = [@a]
    @pairing.match(players)
    assert_equal(0, $called)
  end

  def test_match_two_players
    players = [@a,@b]
    @pairing.match(players)
    assert_equal(1, $called)
  end

  def test_match_two_players_humans
    @a.name += "_human"
    @b.name += "_human"
    players = [@a,@b]
    @pairing.match(players)
    assert_equal(1, $called)
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

  def test_match_three_players_a_human
    @a.name += "_human"
    players = [@a,@b,@c]
    @pairing.match(players)
    assert_equal(1, $called)
    assert_equal(1, players.size)
    assert_equal(@c, players[0])
  end

  def test_match_three_players_b_human
    @b.name += "_human"
    players = [@a,@b,@c]
    @pairing.match(players)
    assert_equal(1, $called)
    assert_equal(1, players.size)
    assert_equal(@c, players[0])
  end

  def test_match_three_players_c_human
    @c.name += "_human"
    players = [@a,@b,@c]
    @pairing.match(players)
    assert_equal(1, $called)
    assert_equal(1, players.size)
    assert_equal(@c, players[0])
  end

  def test_match_three_players_ab_human
    @a.name += "_human"
    @b.name += "_human"
    players = [@a,@b,@c]
    @pairing.match(players)
    assert_equal(1, $called)
    assert_equal(1, players.size)
    assert_equal(@b, players[0])
  end

  def test_match_three_players_bc_human
    @b.name += "_human"
    @c.name += "_human"
    players = [@a,@b,@c]
    @pairing.match(players)
    assert_equal(1, $called)
    assert_equal(1, players.size)
    assert_equal(@c, players[0])
  end

  def test_match_four_players
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $called)
  end

  def test_match_four_players_ab_human
    @a.name += "_human"
    @b.name += "_human"
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $paired.size)
    assert(same_pair?([@a,@c], $paired[0]))
    assert(same_pair?([@b,@d], $paired[1]))
  end

  def test_match_four_players_bc_human
    @b.name += "_human"
    @c.name += "_human"
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $paired.size)
    assert(same_pair?([@a,@b], $paired[0]))
    assert(same_pair?([@c,@d], $paired[1]))
  end

  def test_match_four_players_abc_human
    @a.name += "_human"
    @b.name += "_human"
    @c.name += "_human"
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $paired.size)
    assert(same_pair?([@a,@d], $paired[0]))
    assert(same_pair?([@b,@c], $paired[1]))
  end

  def test_match_four_players_bcd_human
    @b.name += "_human"
    @c.name += "_human"
    @d.name += "_human"
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $paired.size)
    assert(same_pair?([@a,@c], $paired[0]))
    assert(same_pair?([@b,@d], $paired[1]))
  end

  def test_match_four_players_abcd_human
    @a.name += "_human"
    @b.name += "_human"
    @c.name += "_human"
    @d.name += "_human"
    players = [@a,@b,@c,@d]
    @pairing.match(players)
    assert_equal(2, $paired.size)
    assert(same_pair?([@a,@b], $paired[0]))
    assert(same_pair?([@c,@d], $paired[1]))
  end

  def test_match_eight_players_efgh_human
    @e.name += "_human"
    @f.name += "_human"
    @g.name += "_human"
    @h.name += "_human"
    players = [@a,@b,@c,@d,@e,@f,@g,@h]
    @pairing.match(players)
    assert_equal(4, $paired.size)
    assert(same_pair?([@e,@c], $paired[0]))
    assert(same_pair?([@d,@g], $paired[1]))
    assert(same_pair?([@a,@f], $paired[2]))
    assert(same_pair?([@b,@h], $paired[3]))
  end
end

class TestLeastDiff < Test::Unit::TestCase

  class MockLeague
    def initialize
      @players = []
    end

    def add(player)
      @players << player
    end

    def find(name)
      @players.find do |p|
        p.name == name
      end
    end
  end

  def setup
    $league = MockLeague.new

    @pairing= ShogiServer::LeastDiff.new
    $paired = []
    $called = 0
    def @pairing.start_game(p1,p2)
      $called += 1
      $paired << [p1,p2]
    end

    @file = Pathname.new(File.join(File.dirname(__FILE__), "floodgate_history.yaml"))
    @history = ShogiServer::League::Floodgate::History.new @file

    @a = ShogiServer::BasicPlayer.new
    @a.player_id = "a"
    @a.name = "a"
    @a.win  = 1
    @a.loss = 2
    @a.rate = 500
    @b = ShogiServer::BasicPlayer.new
    @b.player_id = "b"
    @b.name = "b"
    @b.win  = 10
    @b.loss = 20
    @b.rate = 800
    @c = ShogiServer::BasicPlayer.new
    @c.player_id = "c"
    @c.name = "c"
    @c.win  = 100
    @c.loss = 200
    @c.rate = 1000
    @d = ShogiServer::BasicPlayer.new
    @d.player_id = "d"
    @d.name = "d"
    @d.win  = 1000
    @d.loss = 2000
    @d.rate = 1500
    @e = ShogiServer::BasicPlayer.new
    @e.player_id = "e"
    @e.name = "e"
    @e.win  = 3000
    @e.loss = 3000
    @e.rate = 2000
    @f = ShogiServer::BasicPlayer.new
    @f.player_id = "f"
    @f.name = "f"
    @f.win  = 4000
    @f.loss = 4000
    @f.rate = 2150
    @g = ShogiServer::BasicPlayer.new
    @g.player_id = "g"
    @g.name = "g"
    @g.win  = 5000
    @g.loss = 5000
    @g.rate = 2500
    @h = ShogiServer::BasicPlayer.new
    @h.player_id = "h"
    @h.name = "h"
    @h.win  = 6000
    @h.loss = 6000
    @h.rate = 3000
    @x = ShogiServer::BasicPlayer.new
    @x.player_id = "x"
    @x.name = "x"

    $league.add(@a)
    $league.add(@b)
    $league.add(@c)
    $league.add(@d)
    $league.add(@e)
    $league.add(@f)
    $league.add(@g)
    $league.add(@h)
    $league.add(@x)
  end

  def teardown
    @file.delete if @file.exist?
  end

  def assert_pairs(x_array, y_array)
    if (x_array.size != y_array.size)
      assert_equal(x_array.size, y_array.size)
      return
    end
    i = 0

    if (x_array.size == 1)
      assert_equal(x_array[0].name, y_array[0].name)
      return
    end

    ret = true
    while i < x_array.size
      if i == x_array.size-1
        assert_equal(x_array[i].name, y_array[i].name)
        break
      end
      px1 = x_array[i]
      px2 = x_array[i+1]
      py1 = y_array[i]
      py2 = y_array[i+1]

      if ! ((px1.name == py1.name && px2.name == py2.name) ||
            (px1.name == py2.name && px2.name == py1.name))
        ret = false
      end
      i += 2
    end

    assert(ret)
  end

  def test_match_one_player
    players = [@a]
    assert_equal(0, @pairing.calculate_diff_with_penalty(players,nil))
    r = @pairing.match(players)
    assert_pairs([@a], r)
  end

  def test_match_two_players
    players = [@a,@b]
    assert_equal(@b.rate-@a.rate, @pairing.calculate_diff_with_penalty([@a,@b],nil))
    assert_equal(@b.rate-@a.rate, @pairing.calculate_diff_with_penalty([@b,@a],nil))
    r = @pairing.match(players)
    assert_pairs([@a,@b], r)
  end

  def test_match_three_players
    players = [@h,@a,@b]
    assert_equal(300,  @pairing.calculate_diff_with_penalty([@a,@b,@h],nil))
    assert_equal(2200, @pairing.calculate_diff_with_penalty([@b,@h,@a],nil))
    r = @pairing.match(players)
    assert_pairs([@a,@b,@h], r)
    assert_pairs([@a,@b,@h], players)
  end

  def test_calculate_diff_with_penalty
    players = [@a,@b]
    assert_equal(@b.rate-@a.rate, @pairing.calculate_diff_with_penalty(players,nil))

    dummy = nil
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-a-b-1", 
       :black => "b",  :white => "a",
       :winner => "a", :loser => "b"}
    end
    @history.update(dummy)
    assert_equal(@b.rate-@a.rate+400, @pairing.calculate_diff_with_penalty(players, @history))
  end

  def test_calculate_diff_with_penalty2
    players = [@a,@b,@g,@h]
    assert_equal(@b.rate-@a.rate+@h.rate-@g.rate, @pairing.calculate_diff_with_penalty(players,nil))
  end

  def test_calculate_diff_with_penalty2_1
    players = [@a,@b,@g,@h]
    assert_equal(@b.rate-@a.rate+@h.rate-@g.rate, @pairing.calculate_diff_with_penalty(players,nil))
    dummy = nil
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-a-b-1", 
       :black => "b",  :white => "a",
       :winner => "a", :loser => "b"}
    end
    @history.update(dummy)
    assert_equal(@b.rate-@a.rate+400+@h.rate-@g.rate, @pairing.calculate_diff_with_penalty(players, @history))
  end

  def test_calculate_diff_with_penalty2_2
    players = [@a,@b,@g,@h]
    assert_equal(@b.rate-@a.rate+@h.rate-@g.rate, @pairing.calculate_diff_with_penalty(players,nil))
    dummy = nil
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-a-b-1", 
       :black => "g",  :white => "h",
       :winner => "h", :loser => "g"}
    end
    @history.update(dummy)
    assert_equal(@b.rate-@a.rate+400+@h.rate-@g.rate, @pairing.calculate_diff_with_penalty(players, @history))
    #assert_equal(@b.rate-@a.rate+400+@h.rate-@g.rate+400, @pairing.calculate_diff_with_penalty(players, [@b,@a,@h,@g]))
  end

  def test_calculate_diff_with_penalty2_3
    players = [@a,@b,@g,@h]
    assert_equal(@b.rate-@a.rate+@h.rate-@g.rate, @pairing.calculate_diff_with_penalty(players,nil))
    dummy = nil
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-a-b-1", 
       :black => "g",  :white => "h",
       :winner => "h", :loser => "g"}
    end
    @history.update(dummy)
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-a-b-1", 
       :black => "b",  :white => "a",
       :winner => "a", :loser => "b"}
    end
    @history.update(dummy)
    assert_equal(@b.rate-@a.rate+400+@h.rate-@g.rate+400, @pairing.calculate_diff_with_penalty(players, @history))
  end

  def test_get_player_rate_0
    assert_equal(2150, @pairing.get_player_rate(@x, @history))

    dummy = nil
    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-x-a-1", 
       :black => "x",  :white => "a",
       :winner => "x", :loser => "a"}
    end
    @history.update(dummy)
    assert_equal(@a.rate+100, @pairing.get_player_rate(@x, @history))

    def @history.make_record(game_result)
      {:game_id => "wdoor+floodgate-900-0-x-b-1", 
       :black => "x",  :white => "b",
       :winner => "b", :loser => "x"}
    end
    @history.update(dummy)

    assert_equal((@a.rate+100+@b.rate-100)/2, @pairing.get_player_rate(@x, @history))
  end
end

