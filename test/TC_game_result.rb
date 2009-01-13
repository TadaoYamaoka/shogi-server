$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/game'

module ShogiServer
  class BasicPlayer
    attr_accessor :sente, :status
  end
end

class TestGameResult < Test::Unit::TestCase
  class DummyGame
    attr_accessor :game_name
  end

  def setup
    @p1 = ShogiServer::BasicPlayer.new
    @p1.sente = true
    @p2 = ShogiServer::BasicPlayer.new
    @p2.sente = false
    @game = DummyGame.new
  end

  def test_game_result_win
    gr = ShogiServer::GameResultWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_abnormal_win
    gr = ShogiServer::GameResultAbnormalWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_kachi_win
    gr = ShogiServer::GameResultKachiWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_illegal_kachi_win
    gr = ShogiServer::GameResultIllegalKachiWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_illegal_move_win
    gr = ShogiServer::GameResultIllegalMoveWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_uchifuzume_win
    gr = ShogiServer::GameResultUchifuzumeWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_oute_kaihi_more_win
    gr = ShogiServer::GameResultOuteKaihiMoreWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_outori_win
    gr = ShogiServer::GameResultOutoriWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_toryo_win
    gr = ShogiServer::GameResultToryoWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_oute_sennichite_win
    gr = ShogiServer::GameResultOuteSennichiteWin.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, true)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_draw
    gr = ShogiServer::GameResultDraw.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, false)
    assert_equal(@p2.last_game_win, false)
  end

  def test_game_result_sennichite_draw
    gr = ShogiServer::GameResultSennichiteDraw.new(@game, @p1, @p2)
    assert_equal(@p1.last_game_win, false)
    assert_equal(@p2.last_game_win, false)
  end

end

