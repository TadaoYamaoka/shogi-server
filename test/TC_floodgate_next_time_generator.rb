$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/league/floodgate'

$topdir = File.expand_path File.dirname(__FILE__)

class TestNextTimeGenerator_900_0 < Test::Unit::TestCase
  def setup
    @next = ShogiServer::League::Floodgate::NextTimeGenerator_Floodgate_900_0.new
  end

  def test_0_min
    now = Time.mktime(2009,12,25,22,0)
    assert_equal(Time.mktime(2009,12,25,22,30), @next.call(now))
  end

  def test_20_min
    now = Time.mktime(2009,12,25,22,20)
    assert_equal(Time.mktime(2009,12,25,22,30), @next.call(now))
  end

  def test_30_min
    now = Time.mktime(2009,12,25,22,30)
    assert_equal(Time.mktime(2009,12,25,23,00), @next.call(now))
  end

  def test_50_min
    now = Time.mktime(2009,12,25,22,50)
    assert_equal(Time.mktime(2009,12,25,23,00), @next.call(now))
  end

  def test_50_min_next_day
    now = Time.mktime(2009,12,25,23,50)
    assert_equal(Time.mktime(2009,12,26,0,0), @next.call(now))
  end

  def test_50_min_next_month
    now = Time.mktime(2009,11,30,23,50)
    assert_equal(Time.mktime(2009,12,1,0,0), @next.call(now))
  end

  def test_50_min_next_year
    now = Time.mktime(2009,12,31,23,50)
    assert_equal(Time.mktime(2010,1,1,0,0), @next.call(now))
  end
end

class TestNextTimeGenerator_3600_0 < Test::Unit::TestCase
  def setup
    @next = ShogiServer::League::Floodgate::NextTimeGenerator_Floodgate_3600_0.new
  end

  def test_22_00
    now = Time.mktime(2009,12,25,22,0)
    assert_equal(Time.mktime(2009,12,25,23,0), @next.call(now))
  end

  def test_22_30
    now = Time.mktime(2009,12,25,22,0)
    assert_equal(Time.mktime(2009,12,25,23,0), @next.call(now))
  end

  def test_23_00
    now = Time.mktime(2009,12,25,23,0)
    assert_equal(Time.mktime(2009,12,26,1,0), @next.call(now))
  end

  def test_23_30
    now = Time.mktime(2009,12,25,23,30)
    assert_equal(Time.mktime(2009,12,26,1,0), @next.call(now))
  end

  def test_00_00
    now = Time.mktime(2009,12,26,0,0)
    assert_equal(Time.mktime(2009,12,26,1,0), @next.call(now))
  end

  def test_23_30_next_month
    now = Time.mktime(2009,11,30,23,30)
    assert_equal(Time.mktime(2009,12,1,1,0), @next.call(now))
  end

  def test_23_30_next_year
    now = Time.mktime(2009,12,31,23,30)
    assert_equal(Time.mktime(2010,1,1,1,0), @next.call(now))
  end
end

