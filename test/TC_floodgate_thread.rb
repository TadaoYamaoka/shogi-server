$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'ostruct'
$topdir = File.expand_path File.dirname(__FILE__)
require 'shogi_server'
require 'shogi_server/league/floodgate'
require 'shogi_server/league/floodgate_thread'
require 'test/mock_log_message'

class MySetupFloodgate < ShogiServer::SetupFloodgate
  def initialize(game_names)
    super
    @is_reload_shogi_server = false
    @is_start_games = false
  end
  attr_reader :is_reload_shogi_server, :is_start_games

  def reload_shogi_server
    @is_reload_shogi_server = true
  end

  def start_games(floodgate)
    @is_start_games = floodgate
  end
end

class TestSetupFloodgate < Test::Unit::TestCase
  def setup
    game_names = %w(floodgate-900-0 floodgate-3600-0)
    @sf = MySetupFloodgate.new game_names
  end

  def test_initialize_empty
    sf = ShogiServer::SetupFloodgate.new []
    thread = sf.start
    assert_nil thread
  end

  def test_mk_leagues
    leagues = @sf.mk_leagues
    assert_equal 2, leagues.size
    assert_equal "floodgate-900-0",  leagues[0].game_name
    assert_equal "floodgate-3600-0", leagues[1].game_name
  end

  def test_next_league
    fa = OpenStruct.new
    now = Time.now
    fa.next_time = now
    fb = OpenStruct.new
    fb.next_time = now + 1
    assert_equal fa.next_time, @sf.next_league([fa]).next_time
    assert_equal fa.next_time, @sf.next_league([fa,fb]).next_time
    assert_equal fa.next_time, @sf.next_league([fb,fa]).next_time
  end

  def test_wait_next_floodgate
    f = OpenStruct.new
    f.next_time = Time.now + 1;
    assert @sf.wait_next_floodgate f
    f.next_time = Time.now - 1;
    assert(!@sf.wait_next_floodgate(f))
  end

  def test_regenerate_leagues
    game_names = %w(floodgate-900-0 floodgate-3600-0)
    now = Time.now
    next_array = []
    next_array << ShogiServer::League::Floodgate.new($league, 
                    {:game_name => "floodgate-900-0",
                     :next_time => (now+100)})
    next_array << ShogiServer::League::Floodgate.new($league, 
                    {:game_name => "floodgate-3600-0",
                     :next_time => (now+200)})
    objs = @sf.regenerate_leagues(next_array)
    assert_equal 2, objs.size
    assert_instance_of ShogiServer::League::Floodgate, objs[0]
    assert_instance_of ShogiServer::League::Floodgate, objs[1]
  end

  def test_start
    def @sf.mk_leagues
      ret = []
      now = Time.now
      ret << ShogiServer::League::Floodgate.new($league, 
                                                {:game_name => "floodgate-900-0",
                                                 :next_time => (now-100)})
      ret << ShogiServer::League::Floodgate.new($league, 
                                                {:game_name => "floodgate-3600-0",
                                                 :next_time => (now-200)})
      ret
    end
    thread = @sf.start
    sleep 1
    assert_instance_of Thread, thread
    assert_equal("floodgate-3600-0", @sf.is_start_games.game_name)
  end
end
