require "baseclient"
include Socket::Constants

class UchifuzumeTest < ReadFileClient
  def test_uchifuzume
    csa = File.open(filepath("uchifuzume.csa")) {|f| f.read}
    handshake(csa)
    result2 = cmd2 "-0064FU"
    result1 = cmd  "%TORYO"
    sleep 1
    result1 += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)
    logout12
    assert_match(/#ILLEGAL_MOVE.*#WIN/m, result1)
    assert_match(/#ILLEGAL_MOVE.*#LOSE/m, result2)
  end

  def est_not_uchifuzume
    csa = File.open(filepath("not_uchifuzume.csa")) {|f| f.read}
    handshake(csa)
    cmd2 "-0092FU"
    cmd  "%TORYO"
    sleep 1
    result1 = read_nonblock(@socket1)
    result2 = read_nonblock(@socket2)
    logout12
    assert_match(/#LOSE/m, result1)
    assert_match(/#WIN/m, result2)
  end
end # Client class

