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

require 'observer'

module ShogiServer # for a namespace
 
# MonitorObserver observes GameResult to send messages to the monitors
# watching the game
#
class MonitorObserver
  def update(game_result)
    game_result.game.each_monitor do |monitor_handler|
      monitor_handler.write_safe(game_result.game.game_id, game_result.result_type)
    end
  end
end

# LoggingObserver appends a result of each game to a log file, which will
# be used to calculate rating scores of players.
#
class LoggingObserver
  def initialize
    @logfile = File.join($league.dir, "00LIST")
  end

  def update(game_result)
    end_time_str = game_result.end_time.strftime("%Y/%m/%d %H:%M:%S")
    black = game_result.black
    white = game_result.white
    black_name = black.rated? ? black.player_id : black.name
    white_name = white.rated? ? white.player_id : white.name
    msg = [end_time_str,
           game_result.log_summary_type,
           game_result.black_result,
           black_name,
           white_name,
           game_result.white_result,
           game_result.game.logfile]
    begin
      # Note that this is proccessed in the gian lock.
      File.open(@logfile, "a") do |f|
        f << msg.join("\t") << "\n"
      end
    rescue => e
      # ignore
      $stderr.puts "Failed to write to the game result file: #{@logfile}" if $DEBUG
    end
  end
end

# Base abstract class for a game result.
# Imediate subclasses are GameResultWin and GameResultDraw.
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
  # Result types to write the main log file such as 'toryo' etc... 
  attr_reader :log_summary_type
  # Time when the game ends
  attr_reader :end_time

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
    @end_time = Time.now
    regist_observers
  end

  def regist_observers
    add_observer MonitorObserver.new
    add_observer LoggingObserver.new

    if League::Floodgate.game_name?(@game.game_name) &&
       @game.sente.player_id && @game.gote.player_id
      path = League::Floodgate.history_file_path(@game.game_name) 
      history = League::Floodgate::History.factory(path)
      add_observer history if history
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

  def black_result
    return "Implemet me!"
  end

  def white_result
    return "Implemet me!"
  end

  def log_summary
    log_board
    log("'summary:%s:%s %s:%s %s" % [@log_summary_type, 
                                     @black.name, black_result,
                                     @white.name, white_result])
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

  def black_result
    return @black == @winner ? "win" : "lose"
  end

  def white_result
    return @black == @winner ? "lose" : "win"
  end
end

class GameResultAbnormalWin < GameResultWin
  def initialize(game, winner, loser)
    super
    @log_summary_type = "abnormal"
    @result_type      = "%TORYO"
  end

  def process
    @winner.write_safe("%TORYO\n#RESIGN\n#WIN\n")
    @loser.write_safe( "%TORYO\n#RESIGN\n#LOSE\n")
    log(@result_type)
    log_summary
    notify
  end
end

class GameResultTimeoutWin < GameResultWin
  def initialize(game, winner, loser)
    super
    @log_summary_type = "time up"
    @result_type      = "#TIME_UP"
  end

  def process
    @winner.write_safe("#TIME_UP\n#WIN\n")
    @loser.write_safe( "#TIME_UP\n#LOSE\n")
    # no log
    log_summary
    notify
  end
end

# A player declares (successful) Kachi
class GameResultKachiWin < GameResultWin
  def initialize(game, winner, loser)
    super
    @log_summary_type = "kachi"
    @result_type      = "%KACHI"
  end

  def process
    @winner.write_safe("%KACHI\n#JISHOGI\n#WIN\n")
    @loser.write_safe( "%KACHI\n#JISHOGI\n#LOSE\n")
    log(@result_type)
    log_summary
    notify
  end
end

# A player declares wrong Kachi
class GameResultIllegalKachiWin < GameResultWin
  def initialize(game, winner, loser)
    super
    @log_summary_type = "illegal kachi"
    @result_type      = "%KACHI"
  end

  def process
    @winner.write_safe("%KACHI\n#ILLEGAL_MOVE\n#WIN\n")
    @loser.write_safe( "%KACHI\n#ILLEGAL_MOVE\n#LOSE\n")
    log(@result_type)
    log_summary
    notify
  end
end

class GameResultIllegalWin < GameResultWin
  def initialize(game, winner, loser, cause)
    super(game, winner, loser)
    @log_summary_type = cause
    @result_type      = "#ILLEGAL_MOVE"
  end

  def process
    @winner.write_safe("#ILLEGAL_MOVE\n#WIN\n")
    @loser.write_safe( "#ILLEGAL_MOVE\n#LOSE\n")
    # no log
    log_summary
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

# This won't happen, though.
#
class GameResultOutoriWin < GameResultIllegalWin
  def initialize(game, winner, loser)
    super(game, winner, loser, "outori")
  end
end

class GameResultToryoWin < GameResultWin
  def initialize(game, winner, loser)
    super
    @log_summary_type = "toryo"
    @result_type      = "%TORYO"
  end

  def process
    @winner.write_safe("%TORYO\n#RESIGN\n#WIN\n")
    @loser.write_safe( "%TORYO\n#RESIGN\n#LOSE\n")
    log(@result_type)
    log_summary
    notify
  end
end

class GameResultOuteSennichiteWin < GameResultWin
  def initialize(game, winner, loser)
    super
    @log_summary_type = "oute_sennichite"
    @result_type      = "#OUTE_SENNICHITE"
  end

  def process
    @winner.write_safe("#OUTE_SENNICHITE\n#WIN\n")
    @loser.write_safe( "#OUTE_SENNICHITE\n#LOSE\n")
    # no log
    log_summary
    notify
  end
end

# Draw
#
class GameResultDraw < GameResult
  def initialize(game, p1, p2)
    super
    p1.last_game_win = false
    p2.last_game_win = false
  end
  
  def black_result
    return "draw"
  end

  def white_result
    return "draw"
  end
end

class GameResultSennichiteDraw < GameResultDraw
  def initialize(game, winner, loser)
    super
    @log_summary_type = "sennichite"
    @result_type      = "#SENNICHITE"
  end

  def process
    @players.each do |player|
      player.write_safe("#SENNICHITE\n#DRAW\n")
    end
    # no log
    log_summary
    notify
  end
end

end # ShogiServer
