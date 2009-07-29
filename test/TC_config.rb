$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
$topdir = File.expand_path(File.dirname(__FILE__))
require 'shogi_server/config'


class TestHash < Test::Unit::TestCase
  def test_merge1
    a = {:a => 1}
    b = {:a => 2}
    a.merge! b
    assert_equal({:a => 2}, a)
  end

  def test_merge2
    a = {:a => 1}
    b = {:b => 2}
    a.merge! b
    assert_equal({:a => 1, :b => 2}, a)
  end

  def test_merge3
    a = {:a => {:aa => 1}}
    b = {:a => {:aa => 2}}
    a.merge! b
    assert_equal({:a => {:aa => 2}}, a)
  end

  def test_merge4
    a = {:a => 1}
    b = {:a => {:aa => 2}}
    a.merge! b
    assert_equal({:a => {:aa => 2}}, a)
  end
end


class TestConfig < Test::Unit::TestCase
  def setup
    remove_config_file
  end

  def teardown
    remove_config_file
  end

  def remove_config_file
    delete_file File.join(File.expand_path(File.dirname(__FILE__)), 
                          ShogiServer::Config::FILENAME)
    delete_file File.join("/", "tmp", ShogiServer::Config::FILENAME)
  end

  def delete_file(path)
    if File.exist? path
      File.delete path
    end
  end

  def test_top_dir1
    expected = File.expand_path(File.dirname(__FILE__)) 
    assert_equal expected, $topdir

    conf = ShogiServer::Config.new
    assert_equal expected, conf[:topdir]
  end

  def test_top_dir2
    topdir_orig = $topdir
    $topdir = "/should_be_replaced"
    conf = ShogiServer::Config.new({:topdir => "/tmp"})
    assert_equal "/tmp", conf[:topdir]
    $topdir = topdir_orig
  end

  def test_top_dir3
    topdir_orig = $topdir
    $topdir = "/should_be_replaced"
    conf = ShogiServer::Config.new({"topdir" => "/tmp"})
    assert_equal "/tmp", conf[:topdir]
    $topdir = topdir_orig
  end

  def test_braces1
    conf = ShogiServer::Config.new({:a => 1})
    assert_equal 1, conf[:a]
  end

  def test_braces2
    conf = ShogiServer::Config.new({:a => {:b => 1}})
    assert_equal 1, conf[:a, :b]
  end

  def test_braces3
    conf = ShogiServer::Config.new({:a => {:b => 1}})
    assert_equal nil, conf[:b]
  end
end

