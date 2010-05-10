require "baseclient"
include Socket::Constants

class OuteSennichiteTest < ReadFileClient
  def test_oute_sennichite
    csa = File.open(filepath("oute_sennichite.csa")) {|f| f.read}
    handshake(csa)
    @p1.wait(/#OUTE_SENNICHITE.#LOSE/m)
    @p2.wait(/#OUTE_SENNICHITE.#WIN/m)
    assert true
    logout12
  end

  def test_oute_sennichite2
    csa = File.open(filepath("oute_sennichite2.csa")) {|f| f.read}
    handshake(csa)
    @p1.wait(/#OUTE_SENNICHITE.#WIN/m)
    @p2.wait(/#OUTE_SENNICHITE.#LOSE/m)
    assert true
    logout12
  end

  def test_oute_sennichite3
    csa = File.open(filepath("oute_sennichite3.csa")) {|f| f.read}
    handshake(csa)
    @p1.wait(/#OUTE_SENNICHITE.#LOSE/m)
    @p2.wait(/#OUTE_SENNICHITE.#WIN/m)
    assert true
    logout12
  end
end # Client class

