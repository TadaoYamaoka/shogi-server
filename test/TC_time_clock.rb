$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'test/mock_player'
require 'shogi_server/board'
require 'shogi_server/game'
require 'shogi_server/player'

class DummyPlayer
  def initialize(mytime)
    @mytime = mytime
  end
  attr_reader :mytime
end

class TestTimeClockFactor < Test::Unit::TestCase
  def test_chess_clock
    c = ShogiServer::TimeClock::factory(1, "hoge-900-0")
    assert_instance_of(ShogiServer::ChessClock, c)

    c = ShogiServer::TimeClock::factory(1, "hoge-1500-60")
    assert_instance_of(ShogiServer::ChessClock, c)
  end

  def test_stop_watch_clock
    c = ShogiServer::TimeClock::factory(1, "hoge-1500-060")
    assert_instance_of(ShogiServer::StopWatchClock, c)
  end
end

class TestChessClock < Test::Unit::TestCase
  def test_time_duration
    tc = ShogiServer::ChessClock.new(1, 1500, 60)
    assert_equal(1, tc.time_duration(nil, 100.1, 100.9))
    assert_equal(1, tc.time_duration(nil, 100, 101))
    assert_equal(1, tc.time_duration(nil, 100.1, 101.9))
    assert_equal(2, tc.time_duration(nil, 100.1, 102.9))
    assert_equal(2, tc.time_duration(nil, 100, 102))
  end

  def test_without_byoyomi
    tc = ShogiServer::ChessClock.new(1, 1500, 0)

    p = DummyPlayer.new 100
    assert(!tc.timeout?(p, 100, 101))
    assert(!tc.timeout?(p, 100, 199))
    assert(tc.timeout?(p, 100, 200))
    assert(tc.timeout?(p, 100, 201))
  end

  def test_with_byoyomi
    tc = ShogiServer::ChessClock.new(1, 1500, 60)

    p = DummyPlayer.new 100
    assert(!tc.timeout?(p, 100, 101))
    assert(!tc.timeout?(p, 100, 259))
    assert(tc.timeout?(p, 100, 260))
    assert(tc.timeout?(p, 100, 261))

    p = DummyPlayer.new 30
    assert(!tc.timeout?(p, 100, 189))
    assert(tc.timeout?(p, 100, 190))
  end

  def test_with_byoyomi2
    tc = ShogiServer::ChessClock.new(1, 0, 60)

    p = DummyPlayer.new 0
    assert(!tc.timeout?(p, 100, 159))
    assert(tc.timeout?(p, 100, 160))
  end
end

class TestChessClockWithLeastZero < Test::Unit::TestCase
  def test_time_duration_within_thinking_time
    tc = ShogiServer::ChessClockWithLeastZero.new(0, 900, 10)
    assert_equal(0, tc.time_duration(100, 100.1, 100.9))  # 0.8
    assert_equal(1, tc.time_duration(100, 100, 101))      # 1
    assert_equal(1, tc.time_duration(100, 100.1, 101.9))  # 1.8
    assert_equal(1, tc.time_duration(1,    100,   101))   # 1
    assert_equal(2, tc.time_duration(100, 100.1, 102.9))  # 2.8
    assert_equal(2, tc.time_duration(100, 100, 102))      # 2

    assert_equal(0, tc.time_duration(100, 100, 99.9))     # -0.1
  end

  def test_time_duration_over_thinking_time
    tc = ShogiServer::ChessClockWithLeastZero.new(0, 900, 10)
    assert_equal(1, tc.time_duration(1,    100.1, 101.9))  # 1.8
    assert_equal(2, tc.time_duration(2,    100.1, 102.9))  # 2.8
  end

  def test_with_byoyomi
    tc = ShogiServer::ChessClockWithLeastZero.new(0, 900, 10)

    p = DummyPlayer.new 100
    assert(!tc.timeout?(p, 100, 101))    # 1
    assert(!tc.timeout?(p, 100, 209))    # 109
    assert(!tc.timeout?(p, 100, 209.9))  # 109.9
    assert(tc.timeout?(p, 100, 210))     # 110
    assert(tc.timeout?(p, 100, 210.1))   # 110.1
    assert(tc.timeout?(p, 100, 211))     # 111
  end

  def test_with_byoyomi2
    tc = ShogiServer::ChessClockWithLeastZero.new(0, 0, 10)

    p = DummyPlayer.new 0
    assert(!tc.timeout?(p, 100, 109))    # 9
    assert(!tc.timeout?(p, 100, 109.9))  # 9.9
    assert(tc.timeout?(p, 100, 110))     # 10
    assert(tc.timeout?(p, 100, 110.1))   # 10.1
    assert(tc.timeout?(p, 100, 110))     # 10.1
  end
end

class TestStopWatchClock < Test::Unit::TestCase
  def test_time_duration
    tc = ShogiServer::StopWatchClock.new(1, 1500, 60)
    assert_equal(0,   tc.time_duration(nil, 100.1, 100.9))
    assert_equal(0,   tc.time_duration(nil, 100, 101))
    assert_equal(0,   tc.time_duration(nil, 100, 159.9))
    assert_equal(60,  tc.time_duration(nil, 100, 160))
    assert_equal(60,  tc.time_duration(nil, 100, 219))
    assert_equal(120, tc.time_duration(nil, 100, 220))
  end

  def test_with_byoyomi
    tc = ShogiServer::StopWatchClock.new(1, 600, 60)

    p = DummyPlayer.new 60
    assert(!tc.timeout?(p, 100, 159))
    assert(tc.timeout?(p, 100, 160))
  end
end

