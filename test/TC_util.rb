$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require 'test/unit'
require 'shogi_server/util'

class TestShogiServer < Test::Unit::TestCase

  def test_datetime2time
    now = DateTime.new(2010, 6, 10, 21, 20, 15) # Thu

    assert_instance_of Time, ShogiServer::datetime2time(now) 
    assert_equal Time.mktime(2010, 6, 10, 21, 20, 15), ShogiServer::datetime2time(now) 
  end

  def test_time2datetime
    now = Time.mktime(2010, 6, 10, 21, 20, 15)
    assert_instance_of DateTime, ShogiServer::time2datetime(now)
    assert_equal DateTime.new(2010, 6, 10, 21, 20, 15), ShogiServer::time2datetime(now)
  end

  def test_parse_dow
    assert_equal 7, ShogiServer.parse_dow("Sun")
    assert_equal 1, ShogiServer.parse_dow("Mon")
    assert_equal 2, ShogiServer.parse_dow("Tue")
    assert_equal 3, ShogiServer.parse_dow("Wed")
    assert_equal 4, ShogiServer.parse_dow("Thu")
    assert_equal 5, ShogiServer.parse_dow("Fri")
    assert_equal 6, ShogiServer.parse_dow("Sat")
    assert_equal 7, ShogiServer.parse_dow("Sunday")
    assert_equal 1, ShogiServer.parse_dow("Monday")
    assert_equal 2, ShogiServer.parse_dow("Tuesday")
    assert_equal 3, ShogiServer.parse_dow("Wednesday")
    assert_equal 4, ShogiServer.parse_dow("Thursday")
    assert_equal 5, ShogiServer.parse_dow("Friday")
    assert_equal 6, ShogiServer.parse_dow("Saturday")
  end

end


class TestMkdir < Test::Unit::TestCase
  def setup
    @test_dir = File.join($topdir, "hoge", "hoo", "foo.txt")
  end

  def teardown
    if FileTest.directory?(File.dirname(@test_dir))
      Dir.rmdir(File.dirname(@test_dir))
      Dir.rmdir(File.join($topdir, "hoge"))
    end
  end

  def test_mkdir_for
    assert !FileTest.directory?(File.dirname(@test_dir))
    ShogiServer::Mkdir.mkdir_for(@test_dir)
    assert FileTest.directory?(File.dirname(@test_dir))
  end

end
