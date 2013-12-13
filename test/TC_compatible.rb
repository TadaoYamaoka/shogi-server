$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/compatible'

class TestCompatibleArray < Test::Unit::TestCase
  def test_sample
    assert [1,2].include?([1,2].sample)
  end
end
