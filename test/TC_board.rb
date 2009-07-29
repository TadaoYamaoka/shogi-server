$:.unshift File.join(File.dirname(__FILE__), "..")

require 'test/unit'
require 'shogi_server'
require 'shogi_server/board'
require 'shogi_server/piece'

class Test_kachi < Test::Unit::TestCase
  def test_kachi_good
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1+HI+HI+KA+KA+OU *  *  *  * 
P2+FU+FU+FU+FU+FU+FU *  *  * 
P+00FU00FU
EOM
    assert_equal(true, b.good_kachi?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P8-HI-HI-KA-KA-OU *  *  *  * 
P9-FU-FU-FU-FU-FU-FU *  *  * 
P-00FU
EOM
    assert_equal(true, b.good_kachi?(false))
  end

  def test_kachi_good
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1+HI+HI+KA+KA+OU *  *  *  * 
P2+FU+FU+FU+FU+FU+FU *  *  * 
P+00FU00FU
EOM
    assert_equal(true, b.good_kachi?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P8-HI-HI-KA-KA-OU *  *  *  * 
P9-FU-FU-FU-FU-FU-FU *  *  * 
P-00FU
EOM
    assert_equal(true, b.good_kachi?(false))
  end

  def test_kachi_bad
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1+HI+HI+KA+KA+OU *  *  *  * 
P2+FU+FU+FU+FU+FU+FU *  *  * 
P+00FU
EOM
    assert_equal(false, b.good_kachi?(true)) # point is not enough

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P8-HI-HI-KA-KA-OU *  *  *  * 
P9-FU-FU-FU-FU-FU-FU *  *  * 
EOM
    assert_equal(false, b.good_kachi?(false)) # point is not enough

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1+HI+HI+KA+KA+OU *  *  *  * 
P2+FU+FU+FU+FU+FU *  *  *  *
P+00FU00FU00FU
EOM
    assert_equal(false, b.good_kachi?(true)) # number on board is not enough

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P8-HI-HI-KA-KA-OU *  *  *  * 
P9-FU-FU-FU-FU-FU *  *  *  * 
P-00FU00FU
EOM
    assert_equal(false, b.good_kachi?(false)) # number on board is not enough

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1+HI+HI+KA+KA+OU *  *  * -HI
P2+FU+FU+FU+FU+FU+FU *  *  * 
P+00FU00FU
EOM
    assert_equal(false, b.good_kachi?(true)) # checkmate

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P8-HI-HI-KA-KA-OU *  *  * +HI
P9-FU-FU-FU-FU-FU-FU *  *  * 
P-00FU
EOM
    assert_equal(false, b.good_kachi?(false)) # checkmate

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1+TO+TO * +TO+TO+OU * +TO * 
P2 *  *  *  *  *  *  *  * +KI
P3 *  *  * +TO+NG+TO+TO+TO+NY
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  * +UM
P6 *  *  * -KI-NG-RY *  *  * 
P7-TO * -TO-NG * -TO-TO-TO * 
P8-RY *  * -NK-TO-OU-TO-TO * 
P9 * -TO *  *  *  *  *  *  * 
P+00KI00KI00KE
P-00KA00GI00KE00KE00KY00KY00KY
-
EOM
    assert_equal(true, b.good_kachi?(false))
  end
end

class Test_gps < Test::Unit::TestCase
  def test_gote_promote
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  *  *  * 
P3-FU * -FU-FU-FU-FU-KA-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 * -FU+FU *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+KE+FU+FU+FU+FU+FU+FU
P8 *  *  *  *  *  *  * +HI * 
P9+KY * +GI+KI+OU+KI+GI+KE+KY
P+00FU
P-00KA
EOM
    assert_equal(:normal, b.handle_one_move("-3377UM"))
  end

  def test_capture_promoted_and_put
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
EOM

    assert_equal(:normal, b.handle_one_move("+7776FU"))
    assert_equal(:normal, b.handle_one_move("-3334FU"))
    assert_equal(:normal, b.handle_one_move("+2726FU"))
    assert_equal(:normal, b.handle_one_move("-4344FU"))
    assert_equal(:normal, b.handle_one_move("+3948GI"))
    assert_equal(:normal, b.handle_one_move("-8242HI"))
    assert_equal(:normal, b.handle_one_move("+5756FU"))
    assert_equal(:normal, b.handle_one_move("-3132GI"))
    assert_equal(:normal, b.handle_one_move("+5968OU"))
    assert_equal(:normal, b.handle_one_move("-5162OU"))
    assert_equal(:normal, b.handle_one_move("+6878OU"))
    assert_equal(:normal, b.handle_one_move("-6272OU"))
    assert_equal(:normal, b.handle_one_move("+4958KI"))
    assert_equal(:normal, b.handle_one_move("-7282OU"))
    assert_equal(:normal, b.handle_one_move("+9796FU"))
    assert_equal(:normal, b.handle_one_move("-9394FU"))
    assert_equal(:normal, b.handle_one_move("+2625FU"))
    assert_equal(:normal, b.handle_one_move("-2233KA"))
    assert_equal(:normal, b.handle_one_move("+3736FU"))
    assert_equal(:normal, b.handle_one_move("-7172GI"))
    assert_equal(:normal, b.handle_one_move("+7968GI"))
    assert_equal(:normal, b.handle_one_move("-4152KI"))
    assert_equal(:normal, b.handle_one_move("+6857GI"))
    assert_equal(:normal, b.handle_one_move("-3243GI"))
    assert_equal(:normal, b.handle_one_move("+6968KI"))
    assert_equal(:normal, b.handle_one_move("-5354FU"))
    assert_equal(:normal, b.handle_one_move("+1716FU"))
    assert_equal(:normal, b.handle_one_move("-1314FU"))
    assert_equal(:normal, b.handle_one_move("+4746FU"))
    assert_equal(:normal, b.handle_one_move("-6364FU"))
    assert_equal(:normal, b.handle_one_move("+4645FU"))
    assert_equal(:normal, b.handle_one_move("-5263KI"))
    assert_equal(:normal, b.handle_one_move("+2937KE"))
    assert_equal(:normal, b.handle_one_move("-7374FU"))
    assert_equal(:normal, b.handle_one_move("+2524FU"))
    assert_equal(:normal, b.handle_one_move("-2324FU"))
    assert_equal(:normal, b.handle_one_move("+4544FU"))
    assert_equal(:normal, b.handle_one_move("-4344GI"))
    assert_equal(:normal, b.handle_one_move("+0045FU"))
    assert_equal(:normal, b.handle_one_move("-4445GI"))
    assert_equal(:normal, b.handle_one_move("+8833UM"))
    assert_equal(:normal, b.handle_one_move("-2133KE"))
    assert_equal(:normal, b.handle_one_move("+0088KA"))
    assert_equal(:normal, b.handle_one_move("-5455FU"))
    assert_equal(:normal, b.handle_one_move("+8855KA"))
    assert_equal(:normal, b.handle_one_move("-4243HI"))
    assert_equal(:normal, b.handle_one_move("+2824HI"))
    assert_equal(:normal, b.handle_one_move("-4554GI"))
    assert_equal(:normal, b.handle_one_move("+0044FU"))
    assert_equal(:normal, b.handle_one_move("-4353HI"))
    assert_equal(:normal, b.handle_one_move("+2422RY"))
    assert_equal(:normal, b.handle_one_move("-5455GI"))
    assert_equal(:normal, b.handle_one_move("+5655FU"))
    assert_equal(:normal, b.handle_one_move("-0056FU"))
    assert_equal(:normal, b.handle_one_move("+5756GI"))
    assert_equal(:normal, b.handle_one_move("-0057FU"))
    assert_equal(:normal, b.handle_one_move("+4857GI"))
    assert_equal(:normal, b.handle_one_move("-9495FU"))
    assert_equal(:normal, b.handle_one_move("+9695FU"))
    assert_equal(:normal, b.handle_one_move("-0096FU"))
    assert_equal(:normal, b.handle_one_move("+9996KY"))
    assert_equal(:normal, b.handle_one_move("-0085KA"))
  end
end


class Test_promote < Test::Unit::TestCase
  def test_fu
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU *
P2 *  *  *  *
P3+FU *  * +HI
P4 * +FU *  *
P5 *  * +FU *
EOM
    assert_equal(:normal, b.handle_one_move("+9392TO"))
    assert_equal(:normal, b.handle_one_move("+8483TO"))
    assert_equal(:illegal, b.handle_one_move("+7574TO"))
    assert_equal(:normal, b.handle_one_move("+6364RY"))
  end
end

class Test_move < Test::Unit::TestCase
  def test_fu
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2 * +FU *
EOM
    assert_equal(:illegal, b.handle_one_move("+8281FU"))
  end
  def test_hi
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2 * +HI *
EOM
    assert_equal(:normal, b.handle_one_move("+8212HI"))
    assert_equal(:illegal, b.handle_one_move("+1223HI"))
  end
  def test_ry
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2 * +RY *
EOM
    assert_equal(:normal, b.handle_one_move("+8212RY"))
    assert_equal(:normal, b.handle_one_move("+1223RY"))
  end
end

class Test_put < Test::Unit::TestCase
  def test_fu
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P+00FU00FU
EOM
    assert_equal(:illegal, b.handle_one_move("+0011FU"))
    assert_equal(:normal, b.handle_one_move("+0022FU"))
  end
  def test_ky
     b = ShogiServer::Board.new
     b.set_from_str(<<EOM)
P1-OU * +OU
P+00KY00KY
EOM
    assert_equal(:illegal, b.handle_one_move("+0011KY"))
    assert_equal(:normal, b.handle_one_move("+0022KY"))
  end

  def test_ke
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P+00KE00KE00KE
EOM
    assert_equal(:illegal, b.handle_one_move("+0011KE"))
    assert_equal(:illegal, b.handle_one_move("+0022KE"))
    assert_equal(:normal, b.handle_one_move("+0033KE"))
  end
end


class Test_2fu < Test::Unit::TestCase
  def test_2fu
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P+00FU00FU
EOM
    assert_equal(:normal, b.handle_one_move("+0022FU"))
    assert_equal(:illegal, b.handle_one_move("+0023FU"))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P+00FU00FU
EOM
    assert_equal(:normal, b.handle_one_move("+0022FU"))
    assert_equal(:normal, b.handle_one_move("+0032FU"))
  end
end

class Test_sennichite < Test::Unit::TestCase
  def test_oute_sennichite0
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU *  * +OU
P2 *  * +HI *
EOM
##    b.history[b.to_s] = 1
    assert_equal(:normal, b.handle_one_move("+7271HI")) #1
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7172HI"))
    assert_equal(:normal, b.handle_one_move("-9291OU"))

    assert_equal(:normal, b.handle_one_move("+7271HI")) # 2
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7172HI"))
    assert_equal(:normal, b.handle_one_move("-9291OU"))

    assert_equal(:normal, b.handle_one_move("+7271HI")) # 3
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7172HI"))
    assert_equal(:normal, b.handle_one_move("-9291OU"))

    assert_equal(:oute_sennichite_sente_lose, b.handle_one_move("+7271HI")) # 4
  end

  def test_oute_sennichite1 #330
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
EOM
b.history[b.to_s] = 1

    assert_equal(:normal, b.handle_one_move("+2726FU"))
    assert_equal(:normal, b.handle_one_move("-8384FU"))
    assert_equal(:normal, b.handle_one_move("+2625FU"))
    assert_equal(:normal, b.handle_one_move("-8485FU"))
    assert_equal(:normal, b.handle_one_move("+6978KI"))
    assert_equal(:normal, b.handle_one_move("-4132KI"))
    assert_equal(:normal, b.handle_one_move("+2524FU"))
    assert_equal(:normal, b.handle_one_move("-2324FU"))
    assert_equal(:normal, b.handle_one_move("+2824HI"))
    assert_equal(:normal, b.handle_one_move("-0023FU"))
    assert_equal(:normal, b.handle_one_move("+2484HI"))
    assert_equal(:normal, b.handle_one_move("-8284HI"))
    assert_equal(:normal, b.handle_one_move("+4938KI"))
    assert_equal(:normal, b.handle_one_move("-9394FU"))
    assert_equal(:normal, b.handle_one_move("+5969OU"))
    assert_equal(:normal, b.handle_one_move("-0049HI"))

    assert_equal(:normal, b.handle_one_move("+6968OU"))
    assert_equal(:normal, b.handle_one_move("-4948RY"))
    assert_equal(:normal, b.handle_one_move("+6869OU"))
    assert_equal(:normal, b.handle_one_move("-4849RY"))

    assert_equal(:normal, b.handle_one_move("+6968OU"))
    assert_equal(:normal, b.handle_one_move("-4948RY"))
    assert_equal(:normal, b.handle_one_move("+6869OU"))
    assert_equal(:normal, b.handle_one_move("-4849RY"))

    assert_equal(:normal, b.handle_one_move("+6968OU"))
    assert_equal(:normal, b.handle_one_move("-4948RY"))
    assert_equal(:normal, b.handle_one_move("+6869OU"))
    assert_equal(:normal, b.handle_one_move("-4849RY"))

    assert_equal(:normal, b.handle_one_move("+6968OU")) # added
    assert_equal(:oute_sennichite_gote_lose, b.handle_one_move("-4948RY"))
  end

  def test_not_oute_sennichite
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU *  * +OU
P2 *  * +HI *
EOM
##    b.history[b.to_s] = 1
    assert_equal(:normal, b.handle_one_move("+7271HI")) #1
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7172HI"))
    assert_equal(:normal, b.handle_one_move("-9291OU"))

    assert_equal(:normal, b.handle_one_move("+7271HI")) # 2
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7174HI")) # stop oute here
    assert_equal(:normal, b.handle_one_move("-9291OU"))

    assert_equal(:normal, b.handle_one_move("+7471HI")) # 3
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7172HI"))
    assert_equal(:normal, b.handle_one_move("-9291OU"))

    assert_equal(:sennichite, b.handle_one_move("+7271HI")) # 4
  end

  def test_sennichite0
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
EOM
    b.history[b.to_s] = 1
    assert_equal(:normal, b.handle_one_move("+7172OU"))
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7271OU"))
    assert_equal(:normal, b.handle_one_move("-9291OU")) # 2

    assert_equal(:normal, b.handle_one_move("+7172OU"))
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7271OU"))
    assert_equal(:normal, b.handle_one_move("-9291OU")) # 3

    assert_equal(:normal, b.handle_one_move("+7172OU"))
    assert_equal(:normal, b.handle_one_move("-9192OU"))
    assert_equal(:normal, b.handle_one_move("+7271OU"))
    assert_equal(:sennichite, b.handle_one_move("-9291OU")) # 4
  end

  def test_sennichite1          # 329
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
EOM
    b.history[b.to_s] = 1

    assert_equal(:normal, b.handle_one_move("+2858HI"))
    assert_equal(:normal, b.handle_one_move("-8252HI"))
    assert_equal(:normal, b.handle_one_move("+5828HI"))
    assert_equal(:normal, b.handle_one_move("-5282HI"))
    assert_equal(:normal, b.handle_one_move("+2858HI"))
    assert_equal(:normal, b.handle_one_move("-8252HI"))
    assert_equal(:normal, b.handle_one_move("+5828HI"))
    assert_equal(:normal, b.handle_one_move("-5282HI"))
    assert_equal(:normal, b.handle_one_move("+2858HI"))
    assert_equal(:normal, b.handle_one_move("-8252HI"))
    assert_equal(:normal, b.handle_one_move("+5828HI"))
    assert_equal(:sennichite, b.handle_one_move("-5282HI"))
  end
end

class Test_checkmate < Test::Unit::TestCase
  def test_ki
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2 * +KI
EOM
    assert_equal(true, b.checkmated?(false)) # gote is loosing
    assert_equal(false, b.checkmated?(true))
  end

  def test_hi
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +HI+OU
EOM
    assert_equal(true, b.checkmated?(false)) # gote is loosing
    assert_equal(false, b.checkmated?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * 
P2 * +HI+OU
EOM
    assert_equal(false, b.checkmated?(false)) # hisha can't capture
    assert_equal(false, b.checkmated?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * 
P2 * +RY+OU
EOM
    assert_equal(true, b.checkmated?(false)) # ryu can capture
    assert_equal(false, b.checkmated?(true))
  end

  def test_KE
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2 *  *  *
P3 * +KE *
EOM
    assert_equal(true, b.checkmated?(false))
    assert_equal(false, b.checkmated?(true))
  end
end

class Test_uchifuzume < Test::Unit::TestCase
  def test_uchifuzume1          # 331
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
EOM

    assert_equal(:normal, b.handle_one_move("+2726FU"))
    assert_equal(:normal, b.handle_one_move("-8384FU"))
    assert_equal(:normal, b.handle_one_move("+2625FU"))
    assert_equal(:normal, b.handle_one_move("-8485FU"))
    assert_equal(:normal, b.handle_one_move("+2524FU"))
    assert_equal(:normal, b.handle_one_move("-2324FU"))
    assert_equal(:normal, b.handle_one_move("+2824HI"))
    assert_equal(:normal, b.handle_one_move("-8586FU"))
    assert_equal(:normal, b.handle_one_move("+8786FU"))
    assert_equal(:normal, b.handle_one_move("-0087FU"))
    assert_equal(:normal, b.handle_one_move("+0023FU"))
    assert_equal(:normal, b.handle_one_move("-8788TO"))
    assert_equal(:normal, b.handle_one_move("+2322TO"))
    assert_equal(:normal, b.handle_one_move("-8879TO"))
    assert_equal(:normal, b.handle_one_move("+2231TO"))
    assert_equal(:normal, b.handle_one_move("-7969TO"))
    assert_equal(:normal, b.handle_one_move("+5969OU"))
    assert_equal(:normal, b.handle_one_move("-8286HI"))
    assert_equal(:normal, b.handle_one_move("+3141TO"))
    assert_equal(:normal, b.handle_one_move("-5141OU"))
    assert_equal(:normal, b.handle_one_move("+2484HI"))
    assert_equal(:normal, b.handle_one_move("-8684HI"))
    assert_equal(:normal, b.handle_one_move("+6978OU"))
    assert_equal(:normal, b.handle_one_move("-8424HI"))
    assert_equal(:normal, b.handle_one_move("+7776FU"))
    assert_equal(:normal, b.handle_one_move("-7374FU"))
    assert_equal(:normal, b.handle_one_move("+7675FU"))
    assert_equal(:normal, b.handle_one_move("-7475FU"))
    assert_equal(:normal, b.handle_one_move("+0079KI"))
    assert_equal(:normal, b.handle_one_move("-7576FU"))
    assert_equal(:normal, b.handle_one_move("+7888OU"))
    assert_equal(:normal, b.handle_one_move("-7677TO"))
    assert_equal(:normal, b.handle_one_move("+8877OU"))
    assert_equal(:normal, b.handle_one_move("-2474HI"))
    assert_equal(:normal, b.handle_one_move("+7788OU"))
    assert_equal(:normal, b.handle_one_move("-0086KI"))
    assert_equal(:normal, b.handle_one_move("+9998KY"))
    assert_equal(:normal, b.handle_one_move("-7424HI"))
    assert_equal(:normal, b.handle_one_move("+0099GI"))
    assert_equal(:normal, b.handle_one_move("-0028HI"))
    assert_equal(:normal, b.handle_one_move("+0078FU"))
    assert_equal(:uchifuzume, b.handle_one_move("-0087FU"))
  end

  def test_uchifuzume2
    # http://wdoor.c.u-tokyo.ac.jp/shogi/tools/view/index.cgi?go_last=on&csa=http%3A%2F%2Fwdoor.c.u-tokyo.ac.jp%2Fshogi%2Flogs%2FLATEST%2Fwdoor%2Bfloodgate-900-0%2Busapyon-on-note%2BKShogi900%2B20080217020012.csa
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-KY-KE * -KI * -OU * -KE-KY
P2 *  * +TO *  *  *  *  *  *
P3 *  *  *  * -KI-KI * -FU *
P4 *  * -FU * -FU-FU-FU *  *
P5 * -RY+GI+OU *  *  * +FU+FU
P6-FU * +FU+KI+GI+FU+FU * +KY
P7 *  *  * -RY *  *  *  *  *
P8 *  *  *  *  *  *  *  *  *
P9+KY+KE *  *  *  *  *  *  *
P+00FU00FU00FU00FU00FU00GI00GI00KA00KE
P-00FU00KA
-
EOM
    assert_equal(:uchifuzume, b.handle_one_move("-0064FU"))
  end

  def test_uchifuzume3
    # http://wdoor.c.u-tokyo.ac.jp/shogi/tools/view/index.cgi?go_last=on&csa=http%3A%2F%2Fwdoor.c.u-tokyo.ac.jp%2Fshogi%2Flogs%2FLATEST%2Fwdoor%2Bfloodgate-900-0%2Busapyon-on-note%2Bgps_normal%2B20080215133008.csa
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1 * -GI * -KI-OU * -GI * -KY
P2 *  *  *  * -FU *  *  *  *
P3+OU * -FU-FU * -FU-KI-FU *
P4+KI+KE-RY * -GI *  *  * -FU
P5 *  *  *  *  *  *  *  *  *
P6+FU *  *  * +KY *  *  * +FU
P7 * +FU *  * +FU *  *  *  *
P8 * +GI *  *  *  *  *  *  *
P9+KY+KE *  *  *  *  *  * -UM
P+00KA00KI00KE00KY00FU00FU00FU
P-00HI00KE00FU00FU00FU00FU00FU
-
EOM
    assert_equal(:normal, b.handle_one_move("-0092FU"))
  end

  def test_ou
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU *  *
P3 * +HI *
EOM
    assert_equal(false, b.uchifuzume?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU *  *
P3 * +RY *
EOM
    assert_equal(true, b.uchifuzume?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P2-OU * +OU
P3+FU *  *
P4 * +RY *
EOM
    assert_equal(false, b.uchifuzume?(true)) # ou can move backward

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P2-OU * +OU
P3+FU * +KA
P4 * +RY *
EOM
    assert_equal(true, b.uchifuzume?(true)) # ou can move backward and kaku can capture it
 end                   


  def test_friend
    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU * -HI
P3 * +RY *
EOM
    assert_equal(false, b.uchifuzume?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU * +FU-HI
P3 * +RY *
EOM
    assert_equal(true, b.uchifuzume?(true)) # hisha blocked by fu

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU *  *
P3-GI+RY *
EOM
    assert_equal(true, b.uchifuzume?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU *  *
P3-KI+RY *
EOM
    assert_equal(false, b.uchifuzume?(true))

    b = ShogiServer::Board.new
    b.set_from_str(<<EOM)
P1-OU * +OU
P2+FU *  *
P3-NG+RY *
EOM
    assert_equal(false, b.uchifuzume?(true))
 end
end

class TestBoardForBuoy < Test::Unit::TestCase
  def setup
    @board = ShogiServer::Board.new
  end

  def test_set_from_moves_empty
    moves = []
    rt = @board.set_from_moves moves
    assert_equal(:normal, rt)
  end

  def test_set_from_moves
    moves = ["+7776FU", "-3334FU"]
    assert_nothing_raised do
      @board.set_from_moves moves
    end

    correct = ShogiServer::Board.new
    correct.set_from_str <<EOF
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU * -FU-FU
P4 *  *  *  *  *  * -FU *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  * +FU *  *  *  *  *  * 
P7+FU+FU * +FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
+
EOF
    assert_equal(correct.to_s, @board.to_s)
  end

  def test_set_from_moves_error1
    moves = ["+7776FU", "-3435FU"]
    assert_raise ArgumentError do
      @board.set_from_moves moves
    end
  end

  def test_set_from_moves_error2
    moves = ["+7776FU", "+8786FU"]
    assert_raise ArgumentError do
      @board.set_from_moves moves
    end
  end
end # TestBoardForBuoy

