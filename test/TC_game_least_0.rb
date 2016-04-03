$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'test/mock_player'
require 'shogi_server/board'
require 'shogi_server/game'
require 'shogi_server/player'

$options = {}
$options["least-time-per-move"] = 0
$options["max-moves"] = 256

def log_message(str)
  $stderr.puts str
end

def log_warning(str)
  $stderr.puts str
end

def log_error(str)
  $stderr.puts str
end

$league = ShogiServer::League.new(File.dirname(__FILE__))
$league.event = "test"

class TestGameWithLeastZero < Test::Unit::TestCase

  def test_new
    game_name = "hoge-1500-10"
    board = ShogiServer::Board.new
    board.initial
    p1 = MockPlayer.new
    p1.sente = true
    p1.name  = "p1"
    p2 = MockPlayer.new
    p2.sente = false
    p2.name  = "p2"
    
    game = ShogiServer::Game.new game_name, p1, p2, board 
    assert_equal "", game.last_move

    p1_out = <<EOF
BEGIN Game_Summary
Protocol_Version:1.2
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{game.game_id}
Name+:p1
Name-:p2
Your_Turn:+
Rematch_On_Draw:NO
To_Move:+
Max_Moves:#{$options["max-moves"]}
BEGIN Time
Time_Unit:1sec
Total_Time:1500
Byoyomi:10
Least_Time_Per_Move:#{$options["least-time-per-move"]}
END Time
BEGIN Position
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
END Position
END Game_Summary
EOF
    assert_equal(p1_out, p1.out.first)

    p2_out = <<EOF
BEGIN Game_Summary
Protocol_Version:1.2
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{game.game_id}
Name+:p1
Name-:p2
Your_Turn:-
Rematch_On_Draw:NO
To_Move:+
Max_Moves:#{$options["max-moves"]}
BEGIN Time
Time_Unit:1sec
Total_Time:1500
Byoyomi:10
Least_Time_Per_Move:#{$options["least-time-per-move"]}
END Time
BEGIN Position
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
END Position
END Game_Summary
EOF
    assert_equal(p2_out, p2.out.first)

    file = Pathname.new(game.logfile)
    log = file.read
    assert_equal(<<EOF, log.gsub(/^\$START_TIME.*?\n/,''))
V2
N+p1
N-p2
'Max_Moves:#{$options["max-moves"]}
'Least_Time_Per_Move:#{$options["least-time-per-move"]}
$EVENT:#{game.game_id}
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
EOF
  end

  def test_new_buoy_1_move
    game_name = "buoyhoge-1500-10"
    board = ShogiServer::Board.new
    board.set_from_moves ["+7776FU"]
    p1 = MockPlayer.new
    p1.sente = true
    p1.name  = "p1"
    p2 = MockPlayer.new
    p2.sente = false
    p2.name  = "p2"
    
    game = ShogiServer::Game.new game_name, p1, p2, board 
    assert_equal "+7776FU,T1", game.last_move

    p1_out = <<EOF
BEGIN Game_Summary
Protocol_Version:1.2
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{game.game_id}
Name+:p1
Name-:p2
Your_Turn:+
Rematch_On_Draw:NO
To_Move:-
Max_Moves:#{$options["max-moves"]}
BEGIN Time
Time_Unit:1sec
Total_Time:1500
Byoyomi:10
Least_Time_Per_Move:#{$options["least-time-per-move"]}
END Time
BEGIN Position
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
+7776FU,T1
END Position
END Game_Summary
EOF
    assert_equal(p1_out, p1.out.first)

    p2_out = <<EOF
BEGIN Game_Summary
Protocol_Version:1.2
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{game.game_id}
Name+:p1
Name-:p2
Your_Turn:-
Rematch_On_Draw:NO
To_Move:-
Max_Moves:#{$options["max-moves"]}
BEGIN Time
Time_Unit:1sec
Total_Time:1500
Byoyomi:10
Least_Time_Per_Move:#{$options["least-time-per-move"]}
END Time
BEGIN Position
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
+7776FU,T1
END Position
END Game_Summary
EOF
    assert_equal(p2_out, p2.out.first)

    file = Pathname.new(game.logfile)
    log = file.read
    assert_equal(<<EOF, log.gsub(/^\$START_TIME.*?\n/,''))
V2
N+p1
N-p2
'Max_Moves:#{$options["max-moves"]}
'Least_Time_Per_Move:#{$options["least-time-per-move"]}
$EVENT:#{game.game_id}
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
'buoy game starting with 1 moves
+7776FU
T1
EOF
  end

  def test_new_buoy_2_moves
    game_name = "buoyhoge-1500-10"
    board = ShogiServer::Board.new
    board.set_from_moves ["+7776FU", "-3334FU"]
    p1 = MockPlayer.new
    p1.sente = true
    p1.name  = "p1"
    p2 = MockPlayer.new
    p2.sente = false
    p2.name  = "p2"
    
    game = ShogiServer::Game.new game_name, p1, p2, board 
    assert_equal "-3334FU,T1", game.last_move

    p1_out = <<EOF
BEGIN Game_Summary
Protocol_Version:1.2
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{game.game_id}
Name+:p1
Name-:p2
Your_Turn:+
Rematch_On_Draw:NO
To_Move:+
Max_Moves:#{$options["max-moves"]}
BEGIN Time
Time_Unit:1sec
Total_Time:1500
Byoyomi:10
Least_Time_Per_Move:#{$options["least-time-per-move"]}
END Time
BEGIN Position
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
+7776FU,T1
-3334FU,T1
END Position
END Game_Summary
EOF
    assert_equal(p1_out, p1.out.first)

    p2_out = <<EOF
BEGIN Game_Summary
Protocol_Version:1.2
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{game.game_id}
Name+:p1
Name-:p2
Your_Turn:-
Rematch_On_Draw:NO
To_Move:+
Max_Moves:#{$options["max-moves"]}
BEGIN Time
Time_Unit:1sec
Total_Time:1500
Byoyomi:10
Least_Time_Per_Move:#{$options["least-time-per-move"]}
END Time
BEGIN Position
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
+7776FU,T1
-3334FU,T1
END Position
END Game_Summary
EOF
    assert_equal(p2_out, p2.out.first)

    file = Pathname.new(game.logfile)
    log = file.read
    assert_equal(<<EOF, log.gsub(/^\$START_TIME.*?\n/,''))
V2
N+p1
N-p2
'Max_Moves:#{$options["max-moves"]}
'Least_Time_Per_Move:#{$options["least-time-per-move"]}
$EVENT:#{game.game_id}
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
'buoy game starting with 2 moves
+7776FU
T1
-3334FU
T1
EOF
  end
  
  def test_monitor_add
    game_name = "hoge-1500-10"
    board = ShogiServer::Board.new
    board.initial
    p1 = MockPlayer.new
    p1.sente = true
    p1.name  = "p1"
    p2 = MockPlayer.new
    p2.sente = false
    p2.name  = "p2"
    
    game = ShogiServer::Game.new game_name, p1, p2, board 
    handler1 = ShogiServer::MonitorHandler1.new p1
    handler2 = ShogiServer::MonitorHandler2.new p2

    assert_equal(0, game.monitors.size)
    game.monitoron(handler1)
    assert_equal(1, game.monitors.size)
    game.monitoron(handler2)
    assert_equal(2, game.monitors.size)
    game.monitoroff(handler1)
    assert_equal(1, game.monitors.size)
    assert_equal(handler2, game.monitors.last)
    game.monitoroff(handler2)
    assert_equal(0, game.monitors.size)
  end

  def test_decide_turns
    p1 = MockPlayer.new
    p1.name = "p1"
    p2 = MockPlayer.new
    p2.name = "p2"

    p1.sente=nil; p2.sente=false
    ShogiServer::Game::decide_turns(p1, "+", p2)
    assert_equal true, p1.sente

    p1.sente=nil; p2.sente=nil
    ShogiServer::Game::decide_turns(p1, "+", p2)
    assert_equal true, p1.sente

    p1.sente=nil; p2.sente=true
    ShogiServer::Game::decide_turns(p1, "-", p2)
    assert_equal false, p1.sente

    p1.sente=nil; p2.sente=nil
    ShogiServer::Game::decide_turns(p1, "-", p2)
    assert_equal false, p1.sente

    p1.sente=nil; p2.sente=false
    ShogiServer::Game::decide_turns(p1, "*", p2)
    assert_equal true, p1.sente

    p1.sente=nil; p2.sente=true
    ShogiServer::Game::decide_turns(p1, "*", p2)
    assert_equal false, p1.sente

    p1.sente=nil; p2.sente=nil
    ShogiServer::Game::decide_turns(p1, "*", p2)
    assert (p1.sente == true  && p2.sente == false) ||
           (p1.sente == false && p2.sente == true)
  end
end

