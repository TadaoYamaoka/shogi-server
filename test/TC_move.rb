$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/move'

class TestMove < Test::Unit::TestCase

  def test_is_drop
    m = ShogiServer::Move.new 6,7,8,9,"FU",true
    assert 6, m.x0.to_s
    assert 7, m.y0.to_s
    assert 8, m.x1.to_s
    assert 9, m.y1.to_s
    assert_equal "FU", m.name
    assert m.sente

    assert !m.promotion
    assert_nil m.captured_piece
    assert !m.captured_piece_promoted
    assert !m.is_drop?

    m = ShogiServer::Move.new 0,0,7,6,"FU",true
    assert m.is_drop?
  end

  def test_set_captured_piece_not_promoted
    m = ShogiServer::Move.new 2,4,2,3,"TO",true
    board = ShogiServer::Board.new # dummy
    fu = ShogiServer::PieceFU.new(board, 2, 3, false, false)
    m.set_captured_piece(fu)

    assert_equal fu, m.captured_piece
  end

  def test_set_captured_piece_promoted
    m = ShogiServer::Move.new 2,4,2,3,"TO",true
    board = ShogiServer::Board.new # dummy
    fu = ShogiServer::PieceFU.new(board, 2, 3, false, true)
    m.set_captured_piece(fu)

    assert_equal fu, m.captured_piece
    assert m.captured_piece_promoted
  end
end

