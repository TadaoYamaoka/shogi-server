$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/board'
require 'shogi_server/piece_ky'
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
    hirate_sfen = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b -";
    assert_equal hirate_sfen, @usi.board2usi(board, board.teban)
  end
end

