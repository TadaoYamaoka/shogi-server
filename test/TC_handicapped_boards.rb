$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/handicapped_boards'

class TestHandicappedGameName < Test::Unit::TestCase

  def test_hclance
    klass = ShogiServer::Login.handicapped_game_name?("hclance_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9 * +KE+GI+KI+OU+KI+GI+KE+KY
+
EOF
    assert_equal(answer, str)
  end

  def test_hcbishop
    klass = ShogiServer::Login.handicapped_game_name?("hcbishop_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
+
EOF
    assert_equal(answer, str)
  end

  def test_hcrook
    klass = ShogiServer::Login.handicapped_game_name?("hcrook_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  *  *  * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
+
EOF
    assert_equal(answer, str)
  end

  def test_hcrooklance
    klass = ShogiServer::Login.handicapped_game_name?("hcrooklance_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  *  *  * 
P9 * +KE+GI+KI+OU+KI+GI+KE+KY
+
EOF
    assert_equal(answer, str)
  end

  def test_hc2p
    klass = ShogiServer::Login.handicapped_game_name?("hc2p_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  *  *  * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
+
EOF
    assert_equal(answer, str)
  end

  def test_hc4p
    klass = ShogiServer::Login.handicapped_game_name?("hc4p_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  *  *  * 
P9 * +KE+GI+KI+OU+KI+GI+KE * 
+
EOF
    assert_equal(answer, str)
  end

  def test_hc6p
    klass = ShogiServer::Login.handicapped_game_name?("hc6p_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  *  *  * 
P9 *  * +GI+KI+OU+KI+GI *  * 
+
EOF
    assert_equal(answer, str)
  end

  def test_hc8p
    klass = ShogiServer::Login.handicapped_game_name?("hc8p_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  *  *  * 
P9 *  *  * +KI+OU+KI *  *  * 
+
EOF
    assert_equal(answer, str)
  end

  def test_hc10p
    klass = ShogiServer::Login.handicapped_game_name?("hc10p_hoge-900-0")
    board = klass.new
    board.initial
    str = board.to_s
    answer = <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  *  *  * 
P9 *  *  *  * +OU *  *  *  * 
+
EOF
    assert_equal(answer, str)
  end

end

