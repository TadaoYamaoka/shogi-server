$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require "test/baseclient"
include Socket::Constants

class NotSennichiteTest < ReadFileClient
  def test_oute_sennichite
    csa = File.open(filepath("not_sennichite.csa")) {|f| f.read}
    handshake(csa)
    assert_no_match /#DRAW/, @p1.message
    assert_no_match /#DRAW/, @p2.message
    logout12
  end
end # Client class

