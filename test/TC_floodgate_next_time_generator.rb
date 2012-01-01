$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server'
require 'shogi_server/league/floodgate'
require 'fileutils'

$topdir = File.expand_path File.dirname(__FILE__)

class TestNextTimeGenerator < Test::Unit::TestCase
  def setup
    @game_name = "floodgate-3600-0"
    @config_path = File.join($topdir, "#{@game_name}.conf")
  end

  def teardown
    if File.exist? @config_path
      FileUtils.rm @config_path
    end
  end

  def test_assure_file_does_not_exist
    assert !File.exist?(@config_path)
  end

  def test_factory_from_config_file
    # no config file
    assert !File.exist?(@config_path)
    assert_instance_of ShogiServer::League::Floodgate::NextTimeGenerator_Floodgate_3600_0, 
                       ShogiServer::League::Floodgate::NextTimeGenerator.factory(@game_name)

    # there is a config file
    FileUtils.touch(@config_path)
    assert_instance_of ShogiServer::League::Floodgate::NextTimeGeneratorConfig,
                       ShogiServer::League::Floodgate::NextTimeGenerator.factory(@game_name)
  end
end

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

    now = Time.mktime(2010,7,25,23,30)
    assert_equal(Time.mktime(2010,7,26,0,0), @next.call(now))
    now = Time.mktime(2010,7,26,23,30)
    assert_equal(Time.mktime(2010,7,27,0,0), @next.call(now))
    now = Time.mktime(2010,7,27,23,30)
    assert_equal(Time.mktime(2010,7,28,0,0), @next.call(now))
    now = Time.mktime(2010,7,28,23,30)
    assert_equal(Time.mktime(2010,7,29,0,0), @next.call(now))
    now = Time.mktime(2010,7,29,23,30)
    assert_equal(Time.mktime(2010,7,30,0,0), @next.call(now))
  end

  def test_50_min_next_month
    now = Time.mktime(2009,11,30,23,50)
    assert_equal(Time.mktime(2009,12,1,0,0), @next.call(now))
  end

  def test_50_min_next_year
    now = Time.mktime(2009,12,31,23,50)
    assert_equal(Time.mktime(2010,1,1,0,0), @next.call(now))
  end

  def test_50_min_new_year
    now = Time.mktime(2012,1,1,0,0)
    assert_equal(Time.mktime(2012,1,1,0,30), @next.call(now))
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

  def test_new_year
    now = Time.mktime(2012,1,1,0,0)
    assert_equal(Time.mktime(2012,1,1,1,0), @next.call(now))
  end
end

class TestNextTimeGeneratorConfig < Test::Unit::TestCase
  def setup
  end

  def test_read
    now = DateTime.new(2010, 6, 10, 21, 20, 15) # Thu
    assert_equal DateTime.parse("10-06-2010 21:20:15"), now

    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Thu 22:00"]
    assert_instance_of Time, ntc.call(now)
    assert_equal Time.parse("10-06-2010 22:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Thu 22:15"]
    assert_equal Time.parse("10-06-2010 22:15"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Fri 22:00"]
    assert_equal Time.parse("11-06-2010 22:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Sat 22:00"]
    assert_equal Time.parse("12-06-2010 22:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Sun 22:00"]
    assert_equal Time.parse("13-06-2010 22:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Mon 22:00"]
    assert_equal Time.parse("14-06-2010 22:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Thu 20:00"]
    assert_equal Time.parse("17-06-2010 20:00"), ntc.call(now)
  end

  def test_next_year01
    now = DateTime.new(2011, 12, 30, 21, 20, 15) # Fri
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Sun 00:00"]
    assert_equal Time.parse("01-01-2012 00:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Sun 01:00"]
    assert_equal Time.parse("01-01-2012 01:00"), ntc.call(now)
  end

  def test_next_year02
    now = DateTime.new(2011, 12, 30, 21, 20, 15) # Fri
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Mon 00:00"]
    assert_equal Time.parse("02-01-2012 00:00"), ntc.call(now)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Mon 01:00"]
    assert_equal Time.parse("02-01-2012 01:00"), ntc.call(now)
  end

  def test_read_time
    now = Time.mktime(2010, 6, 10, 21, 20, 15)
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Thu 22:00"]
    assert_instance_of Time, ntc.call(now)
  end

  def test_read_change
    now = DateTime.new(2010, 6, 10, 21, 59, 59) # Thu
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Thu 22:00"]
    assert_equal Time.parse("10-06-2010 22:00"), ntc.call(now)

    now = DateTime.new(2010, 6, 10, 22, 0, 0) # Thu
    ntc = ShogiServer::League::Floodgate::NextTimeGeneratorConfig.new ["Thu 22:00"]
    assert_equal Time.parse("17-06-2010 22:00"), ntc.call(now)
  end
end
