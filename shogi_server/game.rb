## $Id$

## Copyright (C) 2004 NABEYA Kenichi (aka nanami@2ch)
## Copyright (C) 2007-2008 Daigo Moriwaki (daigo at debian dot org)
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'shogi_server/league/floodgate'
require 'observer'

module ShogiServer # for a namespace

# MonitorObserver obserers GameResult to send messages to the monotors
# watching the game
#
class MonitorObserver
  def update(game_result)
    game_result.game.each_monitor do |monitor|
      monitor.write_safe("##[MONITOR][%s] %s\n" % [game_result.game.game_id, game_result.result_type])
    end
  end
end

# Base class for a game result
#
class GameResult
  include Observable

  # Game object
  attr_reader :game
  # Array of players
  attr_reader :players
  # Black player object
  attr_reader :black
  # White plyer object
  attr_reader :white
  # Command to send monitors such as '%TORYO' etc...
  attr_reader :result_type

  def initialize(game, p1, p2)
    @game = game
    @players = [p1, p2]
    if p1.sente && !p2.sente
      @black, @white = p1, p2
    elsif !p1.sente && p2.sente
      @black, @white = p2, p1
    else
      raise "Never reached!"
    end
    @players.each do |player|
      player.status = "connected"
    end
    @result_type = ""

    regist_observers
  end

  def regist_observers
    add_observer MonitorObserver.new

    if League::Floodgate.game_name?(@game.game_name) &&
       @game.sente.player_id &&
       @game.gote.player_id &&
       $options["floodgate-history"]
      add_observer League::Floodgate::History.factory
    end
  end

  def process
    raise "Implement me!"
  end

  def notify
    changed
    notify_observers(self)
  end

  def log(str)
    @game.log_game(str)
  end

  def log_board
    log(@game.board.to_s.gsub(/^/, "\'").chomp)
  end

end

class GameResultWin < GameResult
  attr_reader :winner, :loser

  def initialize(game, winner, loser)
    super
    @winner, @loser = winner, loser
    @winner.last_game_win = true
    @loser.last_game_win  = false
  end

  def log_summary(type)
    log_board

    black_result = white_result = ""
    if @black == @winner
      black_result = "win"
      white_result = "lose"
    else
      black_result = "lose"
      white_result = "win"
    end
    log("'summary:%s:%s %s:%s %s" % [type, 
                                     @black.name, black_result,
                                     @white.name, white_result])

  end
end

class GameResultAbnormalWin < GameResultWin
  def process
    @winner.write_safe("%TORYO\n#RESIGN\n#WIN\n")
    @loser.write_safe( "%TORYO\n#RESIGN\n#LOSE\n")
    log("%TORYO")
    log_summary("abnormal")
    @result_type = "%TORYO"
    notify
  end
end

class GameResultTimeoutWin < GameResultWin
  def process
    @winner.write_safe("#TIME_UP\n#WIN\n")
    @loser.write_safe( "#TIME_UP\n#LOSE\n")
    log_summary("time up")
    @result_type = "#TIME_UP"
    notify
  end
end

# A player declares (successful) Kachi
class GameResultKachiWin < GameResultWin
  def process
    @winner.write_safe("%KACHI\n#JISHOGI\n#WIN\n")
    @loser.write_safe( "%KACHI\n#JISHOGI\n#LOSE\n")
    log("%KACHI")
    log_summary("kachi")
    @result_type = "%KACHI"
    notify
  end
end

# A player declares wrong Kachi
class GameResultIllegalKachiWin < GameResultWin
  def process
    @winner.write_safe("%KACHI\n#ILLEGAL_MOVE\n#WIN\n")
    @loser.write_safe( "%KACHI\n#ILLEGAL_MOVE\n#LOSE\n")
    log("%KACHI")
    log_summary("illegal kachi")
    @result_type = "%KACHI"
    notify
  end
end

class GameResultIllegalWin < GameResultWin
  def initialize(game, winner, loser, cause)
    super(game, winner, loser)
    @cause = cause
  end

  def process
    @winner.write_safe("#ILLEGAL_MOVE\n#WIN\n")
    @loser.write_safe( "#ILLEGAL_MOVE\n#LOSE\n")
    log_summary(@cause)
    @result_type = "#ILLEGAL_MOVE"
    notify
  end
end

class GameResultIllegalMoveWin < GameResultIllegalWin
  def initialize(game, winner, loser)
    super(game, winner, loser, "illegal move")
  end
end

class GameResultUchifuzumeWin < GameResultIllegalWin
  def initialize(game, winner, loser)
    super(game, winner, loser, "uchifuzume")
  end
end

class GameResultOuteKaihiMoreWin < GameResultIllegalWin
  def initialize(game, winner, loser)
    super(game, winner, loser, "oute_kaihimore")
  end
end

class GameResultOutoriWin < GameResultWin
  def initialize(game, winner, loser)
    super(game, winner, loser)
  end
end

class GameResultToryoWin < GameResultWin
  def process
    @winner.write_safe("%TORYO\n#RESIGN\n#WIN\n")
    @loser.write_safe( "%TORYO\n#RESIGN\n#LOSE\n")
    log("%TORYO")
    log_summary("toryo")
    @result_type = "%TORYO"
    notify
  end
end

class GameResultOuteSennichiteWin < GameResultWin
  def process
    @winner.write_safe("#OUTE_SENNICHITE\n#WIN\n")
    @loser.write_safe( "#OUTE_SENNICHITE\n#LOSE\n")
    log_summary("oute_sennichite")
    @result_type = "#OUTE_SENNICHITE"
    notify
  end
end

class GameResultDraw < GameResult
  def initialize(game, p1, p2)
    super
    p1.last_game_win = false
    p2.last_game_win = false
  end
  
  def log_summary(type)
    log_board
    log("'summary:%s:%s draw:%s draw" % [type, @black.name, @white.name])
  end
end

class GameResultSennichiteDraw < GameResultDraw
  def process
    @players.each do |player|
      player.write_safe("#SENNICHITE\n#DRAW\n")
    end
    log_summary("sennichite")
    @result_type = "#SENNICHITE"
    notify
  end
end

class Game
  @@mutex = Mutex.new
  @@time  = 0

  def initialize(game_name, player0, player1)
    @monitors = Array::new
    @game_name = game_name
    if (@game_name =~ /-(\d+)-(\d+)$/)
      @total_time = $1.to_i
      @byoyomi = $2.to_i
    end

    if (player0.sente)
      @sente, @gote = player0, player1
    else
      @sente, @gote = player1, player0
    end
    @sente.socket_buffer.clear
    @gote.socket_buffer.clear
    @current_player, @next_player = @sente, @gote
    @sente.game = self
    @gote.game  = self

    @last_move = ""
    @current_turn = 0

    @sente.status = "agree_waiting"
    @gote.status  = "agree_waiting"

    @game_id = sprintf("%s+%s+%s+%s+%s", 
                  $league.event, @game_name, 
                  @sente.name, @gote.name, issue_current_time)
    
    now = Time.now
    log_dir_name = File.join($league.dir, 
                             now.strftime("%Y"),
                             now.strftime("%m"),
                             now.strftime("%d"))
    FileUtils.mkdir_p(log_dir_name) unless File.exist?(log_dir_name)
    @logfile = File.join(log_dir_name, @game_id + ".csa")

    $league.games[@game_id] = self

    log_message(sprintf("game created %s", @game_id))

    @board = Board::new
    @board.initial
    @start_time = nil
    @fh = open(@logfile, "w")
    @fh.sync = true
    @result = nil

    propose
  end
  attr_accessor :game_name, :total_time, :byoyomi, :sente, :gote, :game_id, :board, :current_player, :next_player, :fh, :monitors
  attr_accessor :last_move, :current_turn
  attr_reader   :result

  def rated?
    @sente.rated? && @gote.rated?
  end

  def turn?(player)
    return player.status == "game" && @current_player == player
  end

  def monitoron(monitor)
    @monitors.delete(monitor)
    @monitors.push(monitor)
  end

  def monitoroff(monitor)
    @monitors.delete(monitor)
  end

  def each_monitor
    @monitors.each do |monitor|
      yield monitor
    end
  end

  def log_game(str)
    if @fh.closed?
      log_error("Failed to write to Game[%s]'s log file: %s" %
                [@game_id, str])
    end
    @fh.printf("%s\n", str)
  end

  def reject(rejector)
    @sente.write_safe(sprintf("REJECT:%s by %s\n", @game_id, rejector))
    @gote.write_safe(sprintf("REJECT:%s by %s\n", @game_id, rejector))
    finish
  end

  def kill(killer)
    [@sente, @gote].each do |player|
      if ["agree_waiting", "start_waiting"].include?(player.status)
        reject(killer.name)
        return # return from this method
      end
    end
    
    if (@current_player == killer)
      result = GameResultAbnormalWin.new(self, @next_player, @current_player)
      result.process
      finish
    end
  end

  def finish
    log_message(sprintf("game finished %s", @game_id))
    @fh.printf("'$END_TIME:%s\n", Time::new.strftime("%Y/%m/%d %H:%M:%S"))    
    @fh.close

    @sente.game = nil
    @gote.game = nil
    @sente.status = "connected"
    @gote.status = "connected"

    if (@current_player.protocol == LoginCSA::PROTOCOL)
      @current_player.finish
    end
    if (@next_player.protocol == LoginCSA::PROTOCOL)
      @next_player.finish
    end
    @monitors = Array::new
    @sente = nil
    @gote = nil
    @current_player = nil
    @next_player = nil
    $league.games.delete(@game_id)
  end

  # class Game
  def handle_one_move(str, player)
    unless turn?(player)
      return false if str == :timeout

      @fh.puts("'Deferred %s" % [str])
      log_warning("Deferred a move [%s] scince it is not %s 's turn." %
                  [str, player.name])
      player.socket_buffer << str # always in the player's thread
      return nil
    end

    finish_flag = true
    @end_time = Time::new
    t = [(@end_time - @start_time).floor, Least_Time_Per_Move].max
    
    move_status = nil
    if ((@current_player.mytime - t <= -@byoyomi) && 
        ((@total_time > 0) || (@byoyomi > 0)))
      status = :timeout
    elsif (str == :timeout)
      return false            # time isn't expired. players aren't swapped. continue game
    else
      @current_player.mytime -= t
      if (@current_player.mytime < 0)
        @current_player.mytime = 0
      end

      move_status = @board.handle_one_move(str, @sente == @current_player)
      # log_debug("move_status: %s for %s's %s" % [move_status, @sente == @current_player ? "BLACK" : "WHITE", str])

      if [:illegal, :uchifuzume, :oute_kaihimore].include?(move_status)
        @fh.printf("'ILLEGAL_MOVE(%s)\n", str)
      else
        if [:normal, :outori, :sennichite, :oute_sennichite_sente_lose, :oute_sennichite_gote_lose].include?(move_status)
          # Thinking time includes network traffic
          @sente.write_safe(sprintf("%s,T%d\n", str, t))
          @gote.write_safe(sprintf("%s,T%d\n", str, t))
          @fh.printf("%s\nT%d\n", str, t)
          @last_move = sprintf("%s,T%d", str, t)
          @current_turn += 1
        end

        @monitors.each do |monitor|
          monitor.write_safe(show.gsub(/^/, "##[MONITOR][#{@game_id}] "))
          monitor.write_safe(sprintf("##[MONITOR][%s] +OK\n", @game_id))
        end
      end
    end

    result = nil
    if (@next_player.status != "game") # rival is logout or disconnected
      result = GameResultAbnormalWin.new(self, @current_player, @next_player)
    elsif (status == :timeout)
      # current_player losed
      result = GameResultTimeoutWin.new(self, @next_player, @current_player)
    elsif (move_status == :illegal)
      result = GameResultIllegalMoveWin.new(self, @next_player, @current_player)
    elsif (move_status == :kachi_win)
      result = GameResultKachiWin.new(self, @current_player, @next_player)
    elsif (move_status == :kachi_lose)
      result = GameResultIllegalKachiWin.new(self, @next_player, @current_player)
    elsif (move_status == :toryo)
      result = GameResultToryoWin.new(self, @next_player, @current_player)
    elsif (move_status == :outori)
      # The current player captures the next player's king
      result = GameResultOutoriWin.new(self, @current_player, @next_player)
    elsif (move_status == :oute_sennichite_sente_lose)
      result = GameResultOuteSennichiteWin.new(self, @gote, @sente) # Sente is checking
    elsif (move_status == :oute_sennichite_gote_lose)
      result = GameResultOuteSennichiteWin.new(self, @sente, @gote) # Gote is checking
    elsif (move_status == :sennichite)
      result = GameResultSennichiteDraw.new(self, @current_player, @next_player)
    elsif (move_status == :uchifuzume)
      # the current player losed
      result = GameResultUchifuzumeWin.new(self, @next_player, @current_player)
    elsif (move_status == :oute_kaihimore)
      # the current player losed
      result = GameResultOuteKaihiMoreWin.new(self, @next_player, @current_player)
    else
      finish_flag = false
    end
    result.process if result
    finish() if finish_flag
    @current_player, @next_player = @next_player, @current_player
    @start_time = Time::new
    return finish_flag
  end

  def start
    log_message(sprintf("game started %s", @game_id))
    @sente.write_safe(sprintf("START:%s\n", @game_id))
    @gote.write_safe(sprintf("START:%s\n", @game_id))
    @sente.mytime = @total_time
    @gote.mytime = @total_time
    @start_time = Time::new
  end

  def propose
    @fh.puts("V2")
    @fh.puts("N+#{@sente.name}")
    @fh.puts("N-#{@gote.name}")
    @fh.puts("$EVENT:#{@game_id}")

    @sente.write_safe(propose_message("+"))
    @gote.write_safe(propose_message("-"))

    now = Time::new.strftime("%Y/%m/%d %H:%M:%S")
    @fh.puts("$START_TIME:#{now}")
    @fh.print <<EOM
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
EOM
    if rated?
      black_name = @sente.rated? ? @sente.player_id : @sente.name
      white_name = @gote.rated?  ? @gote.player_id  : @gote.name
      @fh.puts("'rating:%s:%s" % [black_name, white_name])
    end
  end

  def show()
    str0 = <<EOM
BEGIN Game_Summary
Protocol_Version:1.1
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{@game_id}
Name+:#{@sente.name}
Name-:#{@gote.name}
Rematch_On_Draw:NO
To_Move:+
BEGIN Time
Time_Unit:1sec
Total_Time:#{@total_time}
Byoyomi:#{@byoyomi}
Least_Time_Per_Move:#{Least_Time_Per_Move}
Remaining_Time+:#{@sente.mytime}
Remaining_Time-:#{@gote.mytime}
Last_Move:#{@last_move}
Current_Turn:#{@current_turn}
END Time
BEGIN Position
EOM

    str1 = <<EOM
END Position
END Game_Summary
EOM

    return str0 + @board.to_s + str1
  end

  def propose_message(sg_flag)
    str = <<EOM
BEGIN Game_Summary
Protocol_Version:1.1
Protocol_Mode:Server
Format:Shogi 1.0
Declaration:Jishogi 1.1
Game_ID:#{@game_id}
Name+:#{@sente.name}
Name-:#{@gote.name}
Your_Turn:#{sg_flag}
Rematch_On_Draw:NO
To_Move:+
BEGIN Time
Time_Unit:1sec
Total_Time:#{@total_time}
Byoyomi:#{@byoyomi}
Least_Time_Per_Move:#{Least_Time_Per_Move}
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
P+
P-
+
END Position
END Game_Summary
EOM
    return str
  end
  
  private
  
  def issue_current_time
    time = Time::new.strftime("%Y%m%d%H%M%S").to_i
    @@mutex.synchronize do
      while time <= @@time do
        time += 1
      end
      @@time = time
    end
  end
end

end # ShogiServer
