require 'test/unit'
load '../shogi-server/shogi-server'
require 'fileutils'

class TestPersistent < Test::Unit::TestCase
  def setup
    @filename = File.join(".", "test.yaml")
    if File.exists?(@filename)
      FileUtils.rm(@filename)
    end
    @persistent = ShogiServer::League::Persistent.new(@filename)
    @p = ShogiServer::BasicPlayer.new
    @p.name = "gps_normal"
    @p.player_id = "gps_normal_dummy_id"
    @p.last_game_win = true
  end

  def test_save_player
    @persistent.save(@p)

    p2 = ShogiServer::BasicPlayer.new
    p2.player_id = @p.player_id

    @persistent.load_player(p2)
    assert_equal(p2.last_game_win, false)
  end

  def test_empty_yaml
    count = 0
    @persistent.each_group do |group, players|
      count += 1
    end
    assert_equal(count, 0)
    FileUtils.rm(@filename)
    count = 0
    @persistent.each_group do |group, players|
      count += 1
    end
    assert_equal(count, 0)
  end

  def test_load_player
    filename = File.join(".", "players.yaml")
    persistent = ShogiServer::League::Persistent.new(filename)
    p = ShogiServer::BasicPlayer.new
    p.player_id = "gps_normal+e293220e3f8a3e59f79f6b0efffaa931"
    persistent.load_player(p)

    assert_equal(p.name, "gps_normal")
    assert_equal(p.rate, -1752.0)
    assert_equal(p.modified_at.to_s, "Thu May 08 23:50:54 +0900 2008")
    assert_equal(p.rating_group, 0)
    assert_equal(p.win, 3384.04877829976)
    assert_equal(p.loss, 906.949084230512)
  end

  def test_get_players
    filename = File.join(".", "players.yaml")
    persistent = ShogiServer::League::Persistent.new(filename)
    players = persistent.get_players
    assert_equal(players.size, 295)
  end
end


class TestLeague < Test::Unit::TestCase
  def setup
    @league = ShogiServer::League.new
    @league.dir = "."
    @league.setup_players_database

    @p = ShogiServer::BasicPlayer.new
    @p.name = "test_name"
  end

  def teardown
    @league.shutdown
  end

  def test_add_player
    assert(!@league.find(@p.name))
    @league.add(@p)
    assert(@league.find(@p.name))
    @league.delete(@p)
    assert(!@league.find(@p.name))
  end

  def test_reload
    @league.reload
    assert(true)
  end
end
