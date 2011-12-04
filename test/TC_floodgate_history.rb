$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'yaml'
require 'shogi_server'
require 'shogi_server/player'
require 'shogi_server/league/floodgate'

$league = ShogiServer::League.new(File.dirname(__FILE__))
$league.event = "TC_floodgate_history"

class MockGame
  attr_accessor :game_id, :game_name

  def regist_observers
    # do nothing
  end
end

class MockPlayer < ShogiServer::BasicPlayer
  attr_accessor :status
end

class TestHistory < Test::Unit::TestCase
  def setup
    @orig_logger = $logger
    $logger ||= Logger.new(STDERR)
  end

  def teardown
    $logger = @orig_logger
  end

  def removed_file
    file = Pathname.new "test_floodgate_history.yaml"
    if file.exist?
      file.delete
    end
    assert(!file.exist?)
    return file
  end

  def test_load_no_file
    file = removed_file

    history = ShogiServer::League::Floodgate::History.new(file)
    history.load
    assert(true)
  end

  def test_load_empty_file
    file = removed_file

    file.open("w") {|f| f.write ""}
    assert(file.exist?)

    history = ShogiServer::League::Floodgate::History.new(file)
    history.load
    assert(true)

    a = MockPlayer.new
    a.name = "a"
    a.win  = 1
    a.loss = 2
    a.rate = 0
    a.last_game_win = false
    a.sente = true
    a.status = ""
    b = MockPlayer.new
    b.name = "b"
    b.win  = 10
    b.loss = 20
    b.rate = 1500
    b.last_game_win = true
    b.sente = false
    b.status = ""

    game = MockGame.new
    game.game_id = "dummy_game_id"
    game.game_name = "dummy_game_name"
    
    gr = ShogiServer::GameResult.new(game, a, b)
    history.update(gr)
    assert true
  end
end
