require "baseclient"
include Socket::Constants

class JishogiTest < ReadFileClient
  def test_jishogi_kachi
    csa = File.open(filepath("jishogi_kachi.csa")) {|f| f.read}
    handshake(csa)
    cmd2 "%KACHI"
    sleep 1
    result1 = cmd ""
    result2 = cmd2 ""
    result1 += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)
    logout12
    assert_match(/#JISHOGI.#LOSE/m, result1)
    assert_match(/#JISHOGI.#WIN/m, result2)
  end
end # Client class
