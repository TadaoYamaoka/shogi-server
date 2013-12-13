$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require "test/baseclient"
include Socket::Constants

class JishogiTest < ReadFileClient
  def test_jishogi_kachi
    csa = File.open(filepath("jishogi_kachi.csa")) {|f| f.read}
    handshake(csa)
    @p2.puts "%KACHI"
    @p1.wait(/#JISHOGI\n#LOSE/)
    @p2.wait(/#JISHOGI\n#WIN/)
    assert true
    logout12
  end
end # Client class
