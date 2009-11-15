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

end # ShogiServer

