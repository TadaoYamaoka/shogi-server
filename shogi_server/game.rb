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
require 'shogi_server/game_result'
require 'shogi_server/util'

module ShogiServer # for a namespace

class Game
  # When this duration passes after this object instanciated (i.e.
  # the agree_waiting or start_waiting state lasts too long),
  # the game will be rejected by the Server.
  WAITING_EXPIRATION = 120 # seconds

  @@mutex = Mutex.new
  @@time  = 0

  # Decide an actual turn of each player according to their turn preferences.
  # p2 is a rival player of the p1 player.
  # p1_sente_string must be "*", "+" or "-".
  # After this call, the sente value of each player is always true or false, not
  # nil.
  #
  def Game.decide_turns(p1, p1_sente_string, p2)
    if ((p1_sente_string == "*") && (p2.sente == nil))
      if (rand(2) == 0)
        p1.sente = true
        p2.sente = false
      else
        p1.sente = false
        p2.sente = true
      end
    elsif (p2.sente == true) # rival has higher priority
      p1.sente = false
    elsif (p2.sente == false)
      p1.sente = true
    elsif (p1_sente_string == "+")
      p1.sente = true
      p2.sente = false
    elsif (p1_sente_string == "-")
      p1.sente = false
      p2.sente = true
    else
      ## never reached
    end
  end


  def initialize(game_name, player0, player1, board)
    @monitors = Array::new # array of MonitorHandler*
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
    @board = board
    if @board.teban
      @current_player, @next_player = @sente, @gote
    else
      @current_player, @next_player = @gote, @sente
    end
    @sente.game = self
    @gote.game  = self

    @last_move = @board.initial_moves.empty? ? "" : "%s,T1" % [@board.initial_moves.last]
    @current_turn = @board.initial_moves.size

    @sente.status = "agree_waiting"
    @gote.status  = "agree_waiting"

    @game_id = sprintf("%s+%s+%s+%s+%s", 
                  $league.event, @game_name, 
                  @sente.name, @gote.name, issue_current_time)
    
    # The time when this Game instance was created.
    # Don't be confused with @start_time when the game was started to play.
    @prepared_time = Time.now 
    log_dir_name = File.join($league.dir, 
                             @prepared_time.strftime("%Y"),
                             @prepared_time.strftime("%m"),
                             @prepared_time.strftime("%d"))
    @logfile = File.join(log_dir_name, @game_id + ".csa")
    Mkdir.mkdir_for(@logfile)

    $league.games[@game_id] = self

    log_message(sprintf("game created %s", @game_id))

    @start_time = nil
    @fh = open(@logfile, "w")
    @fh.sync = true
    @result = nil

    propose
  end
  attr_accessor :game_name, :total_time, :byoyomi, :sente, :gote, :game_id, :board, :current_player, :next_player, :fh, :monitors
  attr_accessor :last_move, :current_turn
  attr_reader   :result, :prepared_time

  # Path of a log file for this game.
  attr_reader   :logfile

  def rated?
    @sente.rated? && @gote.rated?
  end

  def turn?(player)
    return player.status == "game" && @current_player == player
  end

  def monitoron(monitor_handler)
    monitoroff(monitor_handler)
    @monitors.push(monitor_handler)
  end

  def monitoroff(monitor_handler)
    @monitors.delete_if {|mon| mon == monitor_handler}
  end

  def each_monitor
    @monitors.each do |monitor_handler|
      yield monitor_handler
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
      @result = GameResultAbnormalWin.new(self, @next_player, @current_player)
      @result.process
      finish
    end
  end

  def finish
    log_message(sprintf("game finished %s", @game_id))

    # In a case where a player in agree_waiting or start_waiting status is
    # rejected, a GameResult object is not yet instanciated.
    # See test/TC_before_agree.rb.
    end_time = @result ? @result.end_time : Time.now
    @fh.printf("'$END_TIME:%s\n", end_time.strftime("%Y/%m/%d %H:%M:%S"))    
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
  def handle_one_move(str, player, end_time)
    unless turn?(player)
      return false if str == :timeout

      @fh.puts("'Deferred %s" % [str])
      log_warning("Deferred a move [%s] scince it is not %s 's turn." %
                  [str, player.name])
      player.socket_buffer << str # always in the player's thread
      return nil
    end

    finish_flag = true
    @end_time = end_time
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
        if :toryo != move_status
          # Thinking time includes network traffic
          @sente.write_safe(sprintf("%s,T%d\n", str, t))
          @gote.write_safe(sprintf("%s,T%d\n", str, t))
          @fh.printf("%s\nT%d\n", str, t)
          @last_move = sprintf("%s,T%d", str, t)
          @current_turn += 1

          @monitors.each do |monitor_handler|
            monitor_handler.write_one_move(@game_id, self)
          end
        end # if
        # if move_status is :toryo then a GameResult message will be sent to monitors   
      end # if
    end

    @result = nil
    if (@next_player.status != "game") # rival is logout or disconnected
      @result = GameResultAbnormalWin.new(self, @current_player, @next_player)
    elsif (status == :timeout)
      # current_player losed
      @result = GameResultTimeoutWin.new(self, @next_player, @current_player)
    elsif (move_status == :illegal)
      @result = GameResultIllegalMoveWin.new(self, @next_player, @current_player)
    elsif (move_status == :kachi_win)
      @result = GameResultKachiWin.new(self, @current_player, @next_player)
    elsif (move_status == :kachi_lose)
      @result = GameResultIllegalKachiWin.new(self, @next_player, @current_player)
    elsif (move_status == :toryo)
      @result = GameResultToryoWin.new(self, @next_player, @current_player)
    elsif (move_status == :outori)
      # The current player captures the next player's king
      @result = GameResultOutoriWin.new(self, @current_player, @next_player)
    elsif (move_status == :oute_sennichite_sente_lose)
      @result = GameResultOuteSennichiteWin.new(self, @gote, @sente) # Sente is checking
    elsif (move_status == :oute_sennichite_gote_lose)
      @result = GameResultOuteSennichiteWin.new(self, @sente, @gote) # Gote is checking
    elsif (move_status == :sennichite)
      @result = GameResultSennichiteDraw.new(self, @current_player, @next_player)
    elsif (move_status == :uchifuzume)
      # the current player losed
      @result = GameResultUchifuzumeWin.new(self, @next_player, @current_player)
    elsif (move_status == :oute_kaihimore)
      # the current player losed
      @result = GameResultOuteKaihiMoreWin.new(self, @next_player, @current_player)
    else
      finish_flag = false
    end
    @result.process if @result
    finish() if finish_flag
    @current_player, @next_player = @next_player, @current_player
    @start_time = Time.now
    return finish_flag
  end

  def is_startable_status?
    return (@sente && @gote &&
            (@sente.status == "start_waiting") &&
            (@gote.status  == "start_waiting"))
  end

  def start
    log_message(sprintf("game started %s", @game_id))
    @sente.status = "game"
    @gote.status  = "game"
    @sente.write_safe(sprintf("START:%s\n", @game_id))
    @gote.write_safe(sprintf("START:%s\n", @game_id))
    @sente.mytime = @total_time
    @gote.mytime = @total_time
    @start_time = Time.now
  end

  def propose
    @fh.puts("V2")
    @fh.puts("N+#{@sente.name}")
    @fh.puts("N-#{@gote.name}")
    @fh.puts("$EVENT:#{@game_id}")

    @sente.write_safe(propose_message("+"))
    @gote.write_safe(propose_message("-"))

    now = Time.now.strftime("%Y/%m/%d %H:%M:%S")
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
    unless @board.initial_moves.empty?
      @fh.puts "'buoy game starting with %d moves" % [@board.initial_moves.size]
      @board.initial_moves.each do |move|
        @fh.puts move
        @fh.puts "T1"
      end
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
To_Move:#{@board.teban ? "+" : "-"}
BEGIN Time
Time_Unit:1sec
Total_Time:#{@total_time}
Byoyomi:#{@byoyomi}
Least_Time_Per_Move:#{Least_Time_Per_Move}
END Time
BEGIN Position
#{Board::INITIAL_HIRATE_POSITION}
#{@board.initial_moves.collect {|m| m + ",T1"}.join("\n")}
END Position
END Game_Summary
EOM
    # An empty @board.initial_moves causes an empty line, which should be
    # eliminated.
    return str.gsub("\n\n", "\n")
  end

  def prepared_expire?
    if @prepared_time && (@prepared_time + WAITING_EXPIRATION < Time.now)
      return true
    end

    return false
  end
  
  private
  
  def issue_current_time
    time = Time.now.strftime("%Y%m%d%H%M%S").to_i
    @@mutex.synchronize do
      while time <= @@time do
        time += 1
      end
      @@time = time
    end
  end
end

end # ShogiServer
