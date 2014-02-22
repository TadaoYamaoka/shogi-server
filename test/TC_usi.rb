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

  def test_usiToCsa
    # 26th Ryuousen 5th match Moriuchi vs Watanabe on Nov 28th, 2013
    usi_moves = %w!7g7f 8c8d 7i6h 3c3d 6g6f 7a6b 5g5f 5c5d 3i4h 3a4b 4i5h 4a3b 6i7h 5a4a 5i6i 6a5b 6h7g 4b3c 8h7i 2b3a 3g3f 4c4d 4h3g 3a6d 5h6g 7c7d 7i6h 5b4c 6i7i 4a3a 7i8h 9c9d 3g4f 6b5c 2i3g 6d7c 1g1f 1c1d 2g2f 3c2d 2h3h 9d9e 1i1h 3a2b 3g2e 4d4e 4f4e 7c1i+ 6h4f 1i4f 4g4f B*5i B*3g 5i3g+ 3h3g B*1i 3g3h 1i4f+ P*4d 4c4d B*7a 4d4c 6g5g 4f5g 7a8b+ P*4d 4e3d 4c3d R*5a 5c4b 5a8a+ S*6i 7h6h 5g6h 3h6h G*5h 8b4f 5h6h 4f6h R*4h G*7i 6i5h+ 6h7h G*6i 7i6i 5h6i B*5g 4h1h+ P*4h 1h2g 5g2d 3d2d 7h6i L*6g S*6h 6g6h+ 6i6h S*5g N*3c 4b3c 2e3c+ 2b3c L*3e P*3d 8a2a G*3a 2a1a 5g6h 7g6h N*6d S*6g 3d3e S*5c 2g3f N*2e 3c4c 5c6d+ 6c6d G*3c 4c5c 3c3b 3a3b N*5e 5d5e 1a5a L*5b L*5d 5c5d 5a5b 5d4e L*4g 3f4g 4h4g 4e3f G*3h!
    uc = ShogiServer::Usi::UsiToCsa.new
    usi_moves.each do |m|
      state, csa = uc.next(m)
      assert_equal(:normal, state)
    end

    cu = ShogiServer::Usi::CsaToUsi.new
    uc.csa_moves.each do |m|
      state, usi = cu.next(m)
      assert_equal(:normal, state)
    end

    assert_equal(usi_moves, cu.usi_moves)
  end
end
