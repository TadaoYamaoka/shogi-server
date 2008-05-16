require "baseclient"
include Socket::Constants

class NotSennichiteTest < ReadFileClient
  def test_oute_sennichite
    csa = File.open(filepath("not_sennichite.csa")) {|f| f.read}
    handshake(csa)
    #cmd2 "%KACHI"
    sleep 1
    result1 = read_nonblock(@socket1)
    result2 = read_nonblock(@socket2)
    logout12
    assert_no_match(/#DRAW/m, result1)
    assert_no_match(/#DRAW/m, result2)
  end
end # Client class

