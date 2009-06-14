require "baseclient"
include Socket::Constants

class OuteSennichiteTest < ReadFileClient
  def test_oute_sennichite
    csa = File.open(filepath("oute_sennichite.csa")) {|f| f.read}
    handshake(csa)
    #cmd2 "%KACHI"
    sleep 1
    result1 = read_nonblock(@socket1)
    result2 = read_nonblock(@socket2)
    logout12
    assert_match(/#OUTE_SENNICHITE.#LOSE/m, result1)
    assert_match(/#OUTE_SENNICHITE.#WIN/m, result2)
  end

  def test_oute_sennichite2
    csa = File.open(filepath("oute_sennichite2.csa")) {|f| f.read}
    handshake(csa)
    #cmd2 "%KACHI"
    sleep 1
    result1 = read_nonblock(@socket1)
    result2 = read_nonblock(@socket2)
    logout12
    assert_match(/#OUTE_SENNICHITE.#WIN/m, result1)
    assert_match(/#OUTE_SENNICHITE.#LOSE/m, result2)
  end

  def test_oute_sennichite3
    csa = File.open(filepath("oute_sennichite3.csa")) {|f| f.read}
    handshake(csa)
    #cmd2 "%KACHI"
    sleep 1
    result1 = read_nonblock(@socket1)
    result2 = read_nonblock(@socket2)
    logout12
    assert_match(/#OUTE_SENNICHITE.#LOSE/m, result1)
    assert_match(/#OUTE_SENNICHITE.#WIN/m, result2)
  end
end # Client class

