$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require "test/baseclient"
include Socket::Constants

# This game has more thatn 256 moves.
# Disableing max-moves, "./shogi-server --max moves 0", is required.

class MaxMovesTest < ReadFileClient
  def test_max_moves_draw
    csa = File.open(filepath("max_moves_draw.csa")) {|f| f.read}
    handshake(csa)
    @p1.wait(/#MAX_MOVES\n#CENSORED/)
    @p2.wait(/#MAX_MOVES\n#CENSORED/)
    assert true
    logout12
  end
end # Client class
