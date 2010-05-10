require "baseclient"
include Socket::Constants

class UchifuzumeTest < ReadFileClient
  def test_uchifuzume
    csa = File.open(filepath("uchifuzume.csa")) {|f| f.read}
    handshake(csa)
    @p2.puts "-0064FU"
    @p1.puts "%TORYO"
    wait_finish
    assert_match(/#ILLEGAL_MOVE.*#WIN/m, @p1.message)
    assert_match(/#ILLEGAL_MOVE.*#LOSE/m, @p2.message)
    logout12
  end

  def test_not_uchifuzume
    csa = File.open(filepath("not_uchifuzume.csa")) {|f| f.read}
    handshake(csa)
    @p2.puts "-0092FU"
    @p1.puts "%TORYO"
    wait_finish
    assert_no_match(/#ILLEGAL_MOVE/, @p1.message)
    assert_no_match(/#ILLEGAL_MOVE/, @p2.message)
    logout12
  end
end # Client class

