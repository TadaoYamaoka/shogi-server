# -*- coding: windows-31j -*-
require "baseclient"
require "kconv"

class TestClientAtmark < BaseClient
  # login with trip
  def set_name
    super
    @game_name = "atmark"
    @p1_name = "B@p1"
    @p2_name = "W@p2"
  end

  def test_toryo
    result, result2 = handshake do
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)

    now = Time.now
    year  = now.strftime("%Y")
    month = now.strftime("%m")
    day   = now.strftime("%d")
    path = File.join( File.dirname(__FILE__), "..", year, month, day, "*atmark-1500-0*")
    log_files = Dir.glob(path)
    assert(!log_files.empty?) 
    sleep 0.1
    log_content = File.read(log_files.sort.last)

    # "$EVENT", "$START_TIME" and "'$END_TIME" are removed since they vary dinamically.
    should_be = <<-EOF
V2
N+atmark_B@p1
N-atmark_W@p2
P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
P2 * -HI *  *  *  *  * -KA * 
P3-FU-FU-FU-FU-FU-FU-FU-FU-FU
P4 *  *  *  *  *  *  *  *  * 
P5 *  *  *  *  *  *  *  *  * 
P6 *  *  *  *  *  *  *  *  * 
P7+FU+FU+FU+FU+FU+FU+FU+FU+FU
P8 * +KA *  *  *  *  * +HI * 
P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
+
'rating:atmark_B@p1+275876e34cf609db118f3d84b799a790:atmark_W@p2+275876e34cf609db118f3d84b799a790
+2726FU
T1
-3334FU
T1
%TORYO
'P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
'P2 * -HI *  *  *  *  * -KA * 
'P3-FU-FU-FU-FU-FU-FU * -FU-FU
'P4 *  *  *  *  *  * -FU *  * 
'P5 *  *  *  *  *  *  *  *  * 
'P6 *  *  *  *  *  *  * +FU * 
'P7+FU+FU+FU+FU+FU+FU+FU * +FU
'P8 * +KA *  *  *  *  * +HI * 
'P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
'+
'summary:toryo:atmark_B@p1 lose:atmark_W@p2 win
EOF

    log_content.gsub!(/^\$.*?\n/m, "")
    log_content.gsub!(/^'\$.*?\n/m, "")
    assert_equal(should_be, log_content)
  end
end

class TestHandicappedGame < BaseClient
  # login with trip
  def set_name
    super
    @game_name = "hc2p_hoge"
    @p1_name = "B"
    @p2_name = "W"
  end

  def test_toryo
    result, result2 = handshake do
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)

    now = Time.now
    year  = now.strftime("%Y")
    month = now.strftime("%m")
    day   = now.strftime("%d")
    path = File.join( File.dirname(__FILE__), "..", year, month, day, "*hc2p_hoge-1500-0*")
    log_files = Dir.glob(path)
    assert(!log_files.empty?) 
    sleep 0.1
    log_content = File.read(log_files.sort.last)

    # "$EVENT", "$START_TIME" and "'$END_TIME" are removed since they vary dinamically.
    should_be = <<-EOF
V2
N+hc2p_hoge_B
N-hc2p_hoge_W
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
'rating:hc2p_hoge_B+275876e34cf609db118f3d84b799a790:hc2p_hoge_W+275876e34cf609db118f3d84b799a790
+2726FU
T1
-3334FU
T1
%TORYO
'P1-KY-KE-GI-KI-OU-KI-GI-KE-KY
'P2 * -HI *  *  *  *  * -KA * 
'P3-FU-FU-FU-FU-FU-FU * -FU-FU
'P4 *  *  *  *  *  * -FU *  * 
'P5 *  *  *  *  *  *  *  *  * 
'P6 *  *  *  *  *  *  * +FU * 
'P7+FU+FU+FU+FU+FU+FU+FU * +FU
'P8 *  *  *  *  *  *  *  *  * 
'P9+KY+KE+GI+KI+OU+KI+GI+KE+KY
'+
'summary:toryo:hc2p_hoge_B lose:hc2p_hoge_W win
EOF

    log_content.gsub!(/^\$.*?\n/m, "")
    log_content.gsub!(/^'\$.*?\n/m, "")
    assert_equal(should_be, log_content)
  end
end


class TestComment < BaseClient
  def test_toryo
    result, result2 = handshake do
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end

  def test_inline_comment
    result, result2 = handshake do
      move "+2625FU,'comment"
      move "-2233KA"
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end

  def test_inline_comment_ja_euc
    result, result2 = handshake do
      move "+2625FU,'日本語EUC"
      move "-2233KA"
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end

  def test_inline_comment_ja_utf8
    result, result2 = handshake do
      move "+2625FU,'日本語UTF8".toutf8
      move "-2233KA"
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end
end


class TestWhiteMovesBlack < BaseClient
  def test_white_moves_black
    result, result2 = handshake do
      move "+9796FU"
      @p2.move "+1716FU"
      wait_finish
    end
    assert(/#ILLEGAL_MOVE/ =~ result)
    assert(/#WIN/  =~ result)
    assert(/#ILLEGAL_MOVE/ =~ result2)
    assert(/#LOSE/ =~ result2)
  end
end


#
# CSA test
#

class TestLoginCSAWithoutTripGoodGamename < CSABaseClient
  def set_name
    super
    @game_name = "csawotrip"
    @p1_name   = "p1"
    @p2_name   = "p2"
  end

  def test_toryo
    result, result2 = handshake do
      @p1.toryo
      @p1.wait_finish
      @p2.wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end
end

class TestLoginCSAWithTripGoodGamename < CSABaseClient
  def set_name
    super
    @game_name = "csawtrip"
    @p1_name   = "p1"
    @p2_name   = "p2"
  end

  def set_player
    super
    @p1.login_command += ",atrip"
    @p2.login_command += ",anothertrip"
  end

  def test_toryo
    result, result2 = handshake do
      @p1.toryo
      @p1.wait_finish
      @p2.wait_finish
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end
end

class TestChallenge < CSABaseClient
  def set_name
    super
    @game_name = "challenge"
    @p1_name   = "p1"
    @p2_name   = "p2"
  end

  def set_player
    super
    @p1.login_command += ",atrip"
    @p2.login_command += ",anothertrip"
  end

  def test_toryo
    result, result2 = handshake do
      @p1.puts "CHALLENGE"
      @p1.wait(/CHALLENGE ACCEPTED/)
      @p2.puts "CHALLENGE"
      @p2.wait(/CHALLENGE ACCEPTED/)
    end
    assert(true)
  end
end

#
# Test Floodgate
#

class TestFloodgateGame < BaseClient
  def set_name
    super
    @game_name = "floodgate"
  end

  def set_player
    @p1 = SocketPlayer.new @game_name, @p1_name, "*"
    @p2 = SocketPlayer.new @game_name, @p2_name, "*"
  end

  def test_game_wait
    @p1.connect
    @p2.connect
    @p1.login
    @p2.login
    @p1.game
    @p2.game
    assert(true)
    logout12
  end
end

class TestFloodgateGameWrongTebam < BaseClient
  def set_name
    super
    @game_name = "floodgate"
  end

  def test_game_wait
    @p1.connect
    @p2.connect
    @p1.login
    @p2.login
    @p1.game
    @p1.wait %r!##\[ERROR\] You are not allowed!
    assert true
    logout12
  end
end




class TestDuplicatedMoves < BaseClient
  def test_defer
    result, result2 = handshake do
      @p1.puts "+7776FU"
      @p1.puts "+8786FU" # defer
      @p1.puts "+9796FU" # defer
      @p2.puts "-7374FU"
      @p2.puts "-8384FU"
      @p2.toryo
      wait_finish
    end
    assert(/#WIN/  =~ result)
    assert(/#LOSE/ =~ result2)
  end

  def test_defer2
    result, result2 = handshake do
      @p1.puts "+7776FU"
      @p1.puts "+8786FU" # defer
      @p1.puts "%TORYO" # defer
      @p2.puts "-7374FU"
      @p2.puts "-8384FU"
      wait_finish
    end
    assert(/#LOSE/  =~ result)
    assert(/#WIN/ =~ result2)
  end

  def test_defer3
    result, result2 = handshake do
      @p1.puts "+7776FU"
      @p1.puts "+8786FU" # defer
      @p2.puts "-7374FU"
      @p2.puts "-8384FU"
      @p1.toryo
      wait_finish
    end
    assert(/#LOSE/  =~ result)
    assert(/#WIN/ =~ result2)
  end
end

class TestFunctionalChatCommand < BaseClient
  def test_chat
    result, result2 = handshake do
      @p1.puts"%%CHAT Hello"
      @p1.wait %r!##\[CHAT\].*Hello!
      @p2.wait %r!##\[CHAT\].*Hello!
    end
    assert true
  end
end




class TestTwoSameMoves < CSABaseClient
  def set_name
    super
    @game_name = "2moves"
    @p1_name   = "p1"
    @p2_name   = "p2"
  end

  def test_two_same_moves
    result, result2 = handshake do
      move  "+2726FU"
      move "-8384FU"
      @p2.puts "-8384FU" # ignored
      sleep 0.1 # wait for finish of the command above
      move "+2625FU"
    end
    assert(/#ILLEGAL_MOVE/ !~ result)
    assert(/#ILLEGAL_MOVE/ !~ result2)
  end
end

