require "baseclient"
require "kconv"

class TestClientAtmark < BaseClient
  # login with trip
  def login
    cmd "LOGIN testsente@p1 dummy x1"
    cmd "%%GAME testClientAtmark-1500-0 +"
    
    cmd2 "LOGIN testgote@p2 dummy2 x1"
    cmd2 "%%CHALLENGE testClientAtmark-1500-0 -"
  end

  def test_toryo
    result, result2 = handshake do
      cmd  "%TORYO"
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)

    now = Time.now
    year  = now.strftime("%Y")
    month = now.strftime("%m")
    day   = now.strftime("%d")
    path = File.join( File.dirname(__FILE__), "..", year, month, day, "*testClientAtmark-1500-0*")
    log_files = Dir.glob(path)
    assert(!log_files.empty?) 
    log_content = File.open(log_files.sort.last).read

    # "$EVENT", "$START_TIME" and "'$END_TIME" are removed since they vary dinamically.
    should_be = <<-EOF
V2
N+testsente@p1
N-testgote@p2
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
'rating:testsente@p1+275876e34cf609db118f3d84b799a790:testgote@p2+c0c40e7a94eea7e2c238b75273087710
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
'summary:toryo:testsente@p1 lose:testgote@p2 win
EOF

    log_content.gsub!(/^\$.*?\n/m, "")
    log_content.gsub!(/^'\$.*?\n/m, "")
    assert_equal(should_be, log_content)
  end
end


class TestComment < BaseClient
  def test_toryo
    result, result2 = handshake do
      cmd  "%TORYO"
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end

  def test_inline_comment
    result, result2 = handshake do
      cmd "+2625FU,'comment"
      cmd2 "-2233KA"
      cmd  "%TORYO"
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end

  def test_inline_comment_ja_euc
    result, result2 = handshake do
      cmd "+2625FU,'“ú–{ŒêEUC"
      cmd2 "-2233KA"
      cmd  "%TORYO"
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end

  def test_inline_comment_ja_utf8
    result, result2 = handshake do
      cmd "+2625FU,'“ú–{ŒêUTF8".toutf8
      cmd2 "-2233KA"
      cmd  "%TORYO"
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end
end


class TestWhiteMovesBlack < BaseClient
  def test_white_moves_black
    result, result2 = handshake do
      cmd  "+9796FU"
      cmd2 "+1716FU"
      sleep 0.5
    end
    assert(/#ILLEGAL_MOVE/ =~ result)
    assert(/#WIN/  =~ result)
    assert(/#ILLEGAL_MOVE/ =~ result2)
    assert(/#LOSE/ =~ result2)
  end
end


class CSABaseClient < BaseClient
  ##
  # In CSA mode, the server decides sente or gote at random; and sockets are closed
  # just after the game ends (i.e. %TORYO is sent)
  # 
  def handshake
    login

    sleep 0.5 # wait for game matching

    str  = cmd  "AGREE"
    str2 = cmd2 "AGREE"

    if /Your_Turn:\+/ =~ str
      @sente = "cmd"
      @sente_socket = @socket1
      @gote  = "cmd2"
      @gote_socket  = @socket2
    else
      @sente = "cmd2"
      @sente_socket = @socket2
      @gote  = "cmd"
      @gote_socket  = @socket1
    end

    yield if block_given?
    
    result  = read_nonblock(@sente_socket)
    result2 = read_nonblock(@gote_socket)
    [result, result2]
  end

  def sente_cmd(str)
    eval "#{@sente} \"#{str}\""
  end

  def gote_cmd(str)
    eval "#{@gote} \"#{str}\""
  end
end

class TestLoginCSAWithoutTripGoodGamename < CSABaseClient
  def login
    cmd  "LOGIN wo_trip_p1 testcase-1500-0"
    cmd2 "LOGIN wo_trip_p2 testcase-1500-0"
  end

  def test_toryo
    result, result2 = handshake do
      sente_cmd("%TORYO")
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end
end

class TestLoginCSAWithTripGoodGamename < CSABaseClient
  def login
    cmd  "LOGIN w_trip_p1 testcase-1500-0,atrip"
    cmd2 "LOGIN w_trip_p2 testcase-1500-0,anothertrip"
  end

  def test_toryo
    result, result2 = handshake do
      sente_cmd "%TORYO"
      sleep 0.5
    end
    assert(/#LOSE/ =~ result)
    assert(/#WIN/  =~ result2)
  end
end

class TestChallenge < CSABaseClient
  def login
    cmd  "LOGIN w_trip_p1 testcase-1500-0,atrip"
    cmd2 "LOGIN w_trip_p2 testcase-1500-0,anothertrip"
  end

  def test_toryo
    result, result2 = handshake do
      sente_cmd "CHALLENGE"
      gote_cmd  "CHALLENGE"
    end
    assert_match(/CHALLENGE ACCEPTED/, result)
    assert_match(/CHALLENGE ACCEPTED/, result2)
  end
end

class TestFloodgateGame < BaseClient
  def login
    classname = self.class.name
    gamename  = "floodgate-900-0"
    cmd "LOGIN sente#{classname} dummy x1"
    cmd "%%GAME #{gamename} *"
    
    cmd2 "LOGIN gote#{classname} dummy2 x1"
    cmd2 "%%GAME #{gamename} *"
  end

  def test_game_wait
    login
    assert(true)
  end
end

class TestFloodgateGameWrongTebam < BaseClient
  def login
    classname = self.class.name
    gamename  = "floodgate-900-0"
    cmd "LOGIN sente#{classname} dummy x1"
    cmd("%%GAME #{gamename} +")
  end

  def test_game_wait
    login
    sleep 1
    reply = read_nonblock(@socket1)
    assert_match(/##\[ERROR\] You are not allowed/m, reply)
  end
end

class TestDuplicatedMoves < BaseClient
  def test_defer
    result, result2 = handshake do
      cmd  "+7776FU"
      cmd  "+8786FU" # defer
      cmd  "+9796FU" # defer
      cmd2 "-7374FU"
      cmd2 "-8384FU"
      cmd2 "%TORYO" # defer
      sleep 1
    end
    assert(/#WIN/  =~ result)
    assert(/#LOSE/ =~ result2)
  end

  def test_defer2
    result, result2 = handshake do
      cmd  "+7776FU"
      cmd  "+8786FU" # defer
      cmd  "%TORYO" # defer
      cmd2 "-7374FU"
      cmd2 "-8384FU"
      sleep 1
    end
    assert(/#LOSE/  =~ result)
    assert(/#WIN/ =~ result2)
  end

  def test_defer3
    result, result2 = handshake do
      cmd  "+7776FU"
      cmd  "+8786FU" # defer
      cmd2 "-7374FU"
      cmd2 "-8384FU"
      cmd  "%TORYO" # defer
      sleep 1
    end
    assert(/#LOSE/  =~ result)
    assert(/#WIN/ =~ result2)
  end
end

class TestFunctionalChatCommand < BaseClient
  def test_chat
    cmd "%%CHAT Hello"
    sleep 1
    str = read_nonblock(@socket2)
    puts str   
    assert("", str)
  end
end
