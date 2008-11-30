$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/board'
require 'shogi_server/piece'

class TestUsi < Test::Unit::TestCase
  def setup
    @usi = ShogiServer::Usi.new
  end

  def test_hirate
    hirate_sfen = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL";
    board = ShogiServer::Board.new
    assert_equal @usi.parseBoard(hirate_sfen, board), 0

    hirate = ShogiServer::Board.new
    hirate.initial
    hirate.teban = nil

    assert_equal hirate.to_s, board.to_s
  end

  def test_hirate_board
    board = ShogiServer::Board.new
    board.initial
    hirate_sfen         = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b -";
    hirate_sfen_escaped = "lnsgkgsnl_1r5b1_ppppppppp_9_9_9_PPPPPPPPP_1B5R1_LNSGKGSNL.b.-";
    assert_equal hirate_sfen, @usi.board2usi(board, board.teban)
    assert_equal hirate_sfen_escaped, ShogiServer::Usi.escape(@usi.board2usi(board, board.teban))
  end

  def test_board_with_hands1
    b = ShogiServer::Board.new
    b.initial
    b.set_from_str(<<EOB)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU *
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
P+00FU
EOB
    assert_equal "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b P", @usi.board2usi(b, b.teban)
  end

  def test_board_with_hands2
    b = ShogiServer::Board.new
    b.initial
    b.set_from_str(<<EOB)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU *
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
P-00FU
EOB
    assert_equal "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b p", @usi.board2usi(b, b.teban)
  end

  def test_board_with_hands3
    b = ShogiServer::Board.new
    b.initial
    b.set_from_str(<<EOB)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU *  *
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
P-00FU00FU
EOB
    assert_equal "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b 2p", @usi.board2usi(b, b.teban)
  end
end
