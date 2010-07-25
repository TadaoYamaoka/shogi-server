$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require 'test/unit'
require 'shogi_server'

class TestableLogger < ShogiServer::Logger
  def initialize(logdev, shift_age = 0, shift_size = 1048576)
    super
    class << @logdev
      attr_accessor :return_age_file_exists
      def age_file_exists?(age_file)
        return @return_age_file_exists || false
      end

      attr_reader :result_rename_file
      def rename_file(old_file, new_file)
        @result_rename_file ||= []
        @result_rename_file << [old_file, new_file]
      end
    end
  end
  attr_reader :logdev

end

class TestLogger < Test::Unit::TestCase
  def setup
    filename = File.join($topdir, "TC_logger_test.log")
    @logger = TestableLogger.new(filename, "daily")
    @logger.formatter = ShogiServer::Formatter.new
    @logger.level = TestableLogger::DEBUG
    @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
  end

  def test_dummy
    assert true
  end

  def test_age_file_name
    time =  Time.mktime(2010, 7, 25, 23, 59, 59)
    assert_equal File.expand_path(File.join($topdir, "2010", "07", "24", "TC_logger_test.log")), 
                 @logger.logdev.age_file_name(time)
  end

  def test_age_file_exists
    assert !@logger.logdev.age_file_exists?(nil)
    @logger.logdev.return_age_file_exists = true
    assert @logger.logdev.age_file_exists?(nil)
  end

  def test_rename_file
    @logger.logdev.rename_file("old", "new")
    assert_equal [["old", "new"]], @logger.logdev.result_rename_file
  end

  def test_move_age_file_in_the_way
    assert !@logger.logdev.age_file_exists?(nil)
    @logger.logdev.move_age_file_in_the_way("hoge.log")
    assert_nil @logger.logdev.result_rename_file

    @logger.logdev.return_age_file_exists = true
    @logger.logdev.move_age_file_in_the_way("hoge.log")
    assert_equal 1, @logger.logdev.result_rename_file.size
    assert_equal "hoge.log", @logger.logdev.result_rename_file.first.first
  end

  def test_log_info
    @logger.info("test_log_info")
    assert true
  end

  def test_shift_log_period
    @logger.info("test_shift_log_period")
    now =  Time.mktime(2010, 7, 25, 23, 59, 59)
    @logger.logdev.shift_log_period(now)
    assert_equal [["/home/daigo/rubyprojects/shogi-server/test/TC_logger_test.log",
        "/home/daigo/rubyprojects/shogi-server/test/2010/07/24/TC_logger_test.log"]], 
        @logger.logdev.result_rename_file
  end
end
