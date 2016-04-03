## $Id$

## Copyright (C) 2004 NABEYA Kenichi (aka nanami@2ch)
## Copyright (C) 2007-2012 Daigo Moriwaki (daigo at debian dot org)
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

require 'kconv'
require 'shogi_server'

module ShogiServer

  class Command
    # Factory method
    #
    def Command.factory(str, player, time=Time.now)
      cmd = nil
      case str 
      when "" 
        cmd = KeepAliveCommand.new(str, player)
      when /^[\+\-][^%]/
        cmd = MoveCommand.new(str, player)
      when /^%[^%]/, :timeout
        cmd = SpecialCommand.new(str, player)
      when :exception
        cmd = ExceptionCommand.new(str, player)
      when /^REJECT/
        cmd = RejectCommand.new(str, player)
      when /^AGREE/
        cmd = AgreeCommand.new(str, player)
      when /^%%SHOW\s+(\S+)/
        game_id = $1
        cmd = ShowCommand.new(str, player, $league.games[game_id])
      when /^%%MONITORON\s+(\S+)/
        game_id = $1
        cmd = MonitorOnCommand.new(str, player, $league.games[game_id])
      when /^%%MONITOROFF\s+(\S+)/
        game_id = $1
        cmd = MonitorOffCommand.new(str, player, $league.games[game_id])
      when /^%%MONITOR2ON\s+(\S+)/
        game_id = $1
        cmd = Monitor2OnCommand.new(str, player, $league.games[game_id])
      when /^%%MONITOR2OFF\s+(\S+)/
        game_id = $1
        cmd = Monitor2OffCommand.new(str, player, $league.games[game_id])
      when /^%%HELP/
        cmd = HelpCommand.new(str, player)
      when /^%%RATING/
        cmd = RatingCommand.new(str, player, $league.rated_players)
      when /^%%VERSION/
        cmd = VersionCommand.new(str, player)
      when /^%%GAME\s*$/
        cmd = GameCommand.new(str, player)
      when /^%%(GAME|CHALLENGE)\s+(\S+)\s+([\+\-\*])\s*$/
        command_name = $1
        game_name = $2
        my_sente_str = $3
        cmd = GameChallengeCommand.new(str, player, 
                                       command_name, game_name, my_sente_str)
      when /^%%(GAME|CHALLENGE)\s+(\S+)/
        msg = "A turn identifier is required"
        cmd = ErrorCommand.new(str, player, msg)
      when /^%%CHAT\s+(.+)/
        message = $1
        cmd = ChatCommand.new(str, player, message, $league.players)
      when /^%%LIST/
        cmd = ListCommand.new(str, player, $league.games)
      when /^%%WHO/
        cmd = WhoCommand.new(str, player, $league.players)
      when /^LOGOUT/
        cmd = LogoutCommand.new(str, player)
      when /^CHALLENGE/
        cmd = ChallengeCommand.new(str, player)
      when /^%%SETBUOY\s+(\S+)\s+(\S+)(.*)/
        game_name = $1
        moves     = $2
        count = 1 # default
        if $3 && /^\s+(\d*)/ =~ $3
          count = $1.to_i
        end
        cmd = SetBuoyCommand.new(str, player, game_name, moves, count)
      when /^%%DELETEBUOY\s+(\S+)/
        game_name = $1
        cmd = DeleteBuoyCommand.new(str, player, game_name)
      when /^%%GETBUOYCOUNT\s+(\S+)/
        game_name = $1
        cmd = GetBuoyCountCommand.new(str, player, game_name)
      when /^%%FORK\s+(\S+)\s+(\S+)(.*)/
        source_game   = $1
        new_buoy_game = $2
        nth_move      = nil
        if $3 && /^\s+(\d+)/ =~ $3
          nth_move = $3.to_i
        end
        cmd = ForkCommand.new(str, player, source_game, new_buoy_game, nth_move)
      when /^%%FORK\s+(\S+)$/
        source_game   = $1
        new_buoy_game = nil
        nth_move      = nil
        cmd = ForkCommand.new(str, player, source_game, new_buoy_game, nth_move)
      when /^\s*$/
        cmd = SpaceCommand.new(str, player)
      when /^%%%[^%]/
        # TODO: just ignore commands specific to 81Dojo.
        # Need to discuss with 81Dojo people.
        cmd = VoidCommand.new(str, player)
      else
        cmd = ErrorCommand.new(str, player)
      end

      cmd.time = time
      player.last_command_at = time
      return cmd
    end

    def initialize(str, player)
      @str    = str
      @player = player
      @time   = Time.now # this should be replaced later with a real time
    end
    attr_accessor :time
  end

  # Dummy command which does nothing.
  #
  class VoidCommand < Command
    def initialize(str, player)
      super
    end

    def call
      return :continue
    end
  end

  # Application-level protocol for Keep-Alive.
  # If the server receives an LF, it sends back an LF.  Note that the 30 sec
  # rule (client may not send LF again within 30 sec) is not implemented
  # yet.
  #
  class KeepAliveCommand < Command
    def initialize(str, player)
      super
    end

    def call
      @player.write_safe("\n")
      return :continue
    end
  end

  # Command of moving a piece.
  #
  class MoveCommand < Command
    def initialize(str, player)
      super
    end

    def call
      if (@player.status == "game")
        array_str = @str.split(",")
        move = array_str.shift
        if @player.game.last_move &&
           @player.game.last_move.split(",").first == move
          log_warning("Received two sequencial identical moves [#{move}] from #{@player.name}. The last one was ignored.")
          return :continue
        end
        additional = array_str.shift
        comment = nil
        if /^'(.*)/ =~ additional
          comment = array_str.unshift("'*#{$1.toeuc}")
        end
        s = @player.game.handle_one_move(move, @player, @time)
        @player.game.log_game(Kconv.toeuc(comment.first)) if (comment && comment.first && !s)
        return :return if (s && @player.protocol == LoginCSA::PROTOCOL)
      end
      return :continue
    end
  end

  # Command like "%TORYO" or :timeout
  #
  class SpecialCommand < Command
    def initialize(str, player)
      super
    end

    def call
      rc = :continue
      if (@player.status == "game")
        rc = in_game_status()
      elsif ["agree_waiting", "start_waiting"].include?(@player.status) 
        rc = in_waiting_status()
      else
        log_error("Received a command [#{@str}] from #{@player.name} in an inappropriate status [#{@player.status}].") unless @str == :timeout
      end
      return rc
    end

    def in_game_status
      rc = :continue

      s = @player.game.handle_one_move(@str, @player, @time)
      rc = :return if (s && @player.protocol == LoginCSA::PROTOCOL)

      return rc
    end

    def in_waiting_status
      rc = :continue

      if @player.game.prepared_expire?
        log_warning("#{@player.status} lasted too long. This play has been expired: %s" % [@player.game.game_id])
        @player.game.reject("the Server (timed out)")
        rc = :return if (@player.protocol == LoginCSA::PROTOCOL)
      end

      return rc
    end
  end

  # Command of :exception
  #
  class ExceptionCommand < Command
    def initialize(str, player)
      super
    end

    def call
      log_error("Failed to receive a message from #{@player.name}.")
      return :return
    end
  end

  # Command of REJECT
  #
  class RejectCommand < Command
    def initialize(str, player)
      super
    end

    def call
      if (@player.status == "agree_waiting")
        @player.game.reject(@player.name)
        return :return if (@player.protocol == LoginCSA::PROTOCOL)
      else
        log_error("Received a command [#{@str}] from #{@player.name} in an inappropriate status [#{@player.status}].")
        @player.write_safe(sprintf("##[ERROR] you are in %s status. REJECT is valid in agree_waiting status\n", @player.status))
      end
      return :continue
    end
  end

  # Command of AGREE
  #
  class AgreeCommand < Command
    def initialize(str, player)
      super
    end

    def call
      if (@player.status == "agree_waiting")
        @player.status = "start_waiting"
        if (@player.game.is_startable_status?)
          @player.game.start
        end
      else
        log_error("Received a command [#{@str}] from #{@player.name} in an inappropriate status [#{@player.status}].")
        @player.write_safe(sprintf("##[ERROR] you are in %s status. AGREE is valid in agree_waiting status\n", @player.status))
      end
      return :continue
    end
  end

  # Base Command calss requiring a game instance
  #
  class BaseCommandForGame < Command
    def initialize(str, player, game)
      super(str, player)
      @game    = game
      @game_id = game ? game.game_id : nil
    end
  end

  # Command of SHOW
  #
  class ShowCommand < BaseCommandForGame
    def initialize(str, player, game)
      super
    end

    def call
      if (@game)
        @player.write_safe(@game.show.gsub(/^/, '##[SHOW] '))
      end
      @player.write_safe("##[SHOW] +OK\n")
      return :continue
    end
  end

  class MonitorHandler
    def initialize(player)
      @player = player
      @type = nil
      @header = nil
    end
    attr_reader :player, :type, :header

    def ==(rhs)
      return rhs != nil &&
             rhs.is_a?(MonitorHandler) &&
             @player == rhs.player &&
             @type   == rhs.type
    end

    def write_safe(game_id, str)
      str.chomp.split("\n").each do |line|
        @player.write_safe("##[%s][%s] %s\n" % [@header, game_id, line.chomp])
      end
      @player.write_safe("##[%s][%s] %s\n" % [@header, game_id, "+OK"])
    end
  end

  class MonitorHandler1 < MonitorHandler
    def initialize(player)
      super
      @type = 1
      @header = "MONITOR"
    end

    def write_one_move(game_id, game)
      write_safe(game_id, game.show.chomp)
    end
  end

  class MonitorHandler2 < MonitorHandler
    def initialize(player)
      super
      @type = 2
      @header = "MONITOR2"
    end

    def write_one_move(game_id, game)
      write_safe(game_id, game.last_move.gsub(",", "\n"))
    end
  end

  # Command of MONITORON
  #
  class MonitorOnCommand < BaseCommandForGame
    def initialize(str, player, game)
      super
    end

    def call
      if (@game)
        monitor_handler = MonitorHandler1.new(@player)
        @game.monitoron(monitor_handler)
        monitor_handler.write_safe(@game_id, @game.show)
      end
      return :continue
    end
  end

  # Command of MONITOROFF
  #
  class MonitorOffCommand < BaseCommandForGame
    def initialize(str, player, game)
      super
    end

    def call
      if (@game)
        @game.monitoroff(MonitorHandler1.new(@player))
      end
      return :continue
    end
  end

  # Command of MONITOR2ON
  #
  class Monitor2OnCommand < BaseCommandForGame
    def initialize(str, player, game)
      super
    end

    def call
      if (@game)
        monitor_handler = MonitorHandler2.new(@player)
        @game.monitoron(monitor_handler)
        lines = IO::readlines(@game.logfile).join("")
        monitor_handler.write_safe(@game_id, lines)
      end
      return :continue
    end
  end

  class Monitor2OffCommand < MonitorOffCommand
    def initialize(str, player, game)
      super
    end

    def call
      if (@game)
        @game.monitoroff(MonitorHandler2.new(@player))
      end
      return :continue
    end
  end

  # Command of HELP
  #
  class HelpCommand < Command
    def initialize(str, player)
      super
    end

    def call
      @player.write_safe(
        %!##[HELP] available commands "%%WHO", "%%CHAT str", "%%GAME game_name +", "%%GAME game_name -"\n!)
      return :continue
    end
  end

  # Command of RATING
  #
  class RatingCommand < Command
    def initialize(str, player, rated_players)
      super(str, player)
      @rated_players = rated_players
    end

    def call
      @rated_players.sort {|a,b| b.rate <=> a.rate}.each do |p|
        @player.write_safe("##[RATING] %s \t %4d @%s\n" % 
                   [p.simple_player_id, p.rate, p.modified_at.strftime("%Y-%m-%d")])
      end
      @player.write_safe("##[RATING] +OK\n")
      return :continue
    end
  end

  # Command of VERSION
  #
  class VersionCommand < Command
    def initialize(str, player)
      super
    end

    def call
      @player.write_safe "##[VERSION] Shogi Server revision #{ShogiServer::Revision}\n"
      @player.write_safe("##[VERSION] +OK\n")
      return :continue
    end
  end

  # Command of GAME
  #
  class GameCommand < Command
    def initialize(str, player)
      super
    end

    def call
      if ((@player.status == "connected") || (@player.status == "game_waiting"))
        @player.status = "connected"
        @player.game_name = ""
      else
        @player.write_safe(sprintf("##[ERROR] you are in %s status. GAME is valid in connected or game_waiting status\n", @player.status))
      end
      return :continue
    end
  end

  # Commando of game challenge
  # TODO make a test case
  #
  class GameChallengeCommand < Command
    def initialize(str, player, command_name, game_name, my_sente_str)
      super(str, player)
      @command_name = command_name
      @game_name    = game_name
      @my_sente_str = my_sente_str
      player.set_sente_from_str(@my_sente_str)
    end

    def call
      if (! Login::good_game_name?(@game_name))
        @player.write_safe(sprintf("##[ERROR] bad game name: %s.\n", @game_name))
        if (/^(.+)-\d+-\d+F?$/ =~ @game_name)
          if Login::good_identifier?($1)
            # do nothing
          else
            @player.write_safe(sprintf("##[ERROR] invalid identifiers are found or too many characters are used.\n"))
          end
        else
          @player.write_safe(sprintf("##[ERROR] game name should consist of three parts like game-1500-60.\n"))
        end
        return :continue
      elsif ((@player.status == "connected") || (@player.status == "game_waiting"))
        ## continue
      else
        @player.write_safe(sprintf("##[ERROR] you are in %s status. GAME is valid in connected or game_waiting status\n", @player.status))
        return :continue
      end

      rival = nil
      if (League::Floodgate.game_name?(@game_name))
        if (@my_sente_str != "*")
          @player.write_safe(sprintf("##[ERROR] You are not allowed to specify TEBAN %s for the game %s\n", @my_sente_str, @game_name))
          return :continue
        end
        @player.sente = nil
      else
        rival = $league.find_rival(@player, @game_name)
        if rival.instance_of?(Symbol)  
          # An error happened. rival is not a player instance, but an error
          # symobl that must be returned to the main routine immediately.
          return rival
        end
      end

      if (rival)
        @player.game_name = @game_name
        Game::decide_turns(@player, @my_sente_str, rival)

        if (Buoy.game_name?(@game_name))
          buoy = Buoy.new # TODO config
          if buoy.is_new_game?(@game_name)
            # The buoy game is not ready yet.
            # When the game is set, it will be started.
            @player.status = "game_waiting"
          else
            buoy_game = buoy.get_game(@game_name)
            if buoy_game.instance_of? NilBuoyGame
              # error. never reach
            end

            moves_array = Board::split_moves(buoy_game.moves)
            board = Board.new
            begin
              board.set_from_moves(moves_array)
            rescue => err
              # it will never happen since moves have already been checked
              log_error "Failed to set up a buoy game: #{moves}"
              return :continue
            end
            buoy.decrement_count(buoy_game)
            Game::new(@player.game_name, @player, rival, board)
          end
        else
          klass = Login.handicapped_game_name?(@game_name) || Board
          board = klass.new
          board.initial
          Game::new(@player.game_name, @player, rival, board)
        end
      else # rival not found
        if (@command_name == "GAME")
          @player.status = "game_waiting"
          @player.game_name = @game_name
        else                # challenge
          @player.write_safe(sprintf("##[ERROR] can't find rival for %s\n", @game_name))
          @player.status = "connected"
          @player.game_name = ""
          @player.sente = nil
        end
      end
      return :continue
    end
  end

  # Command of CHAT
  #
  class ChatCommand < Command

    # players array of [name, player]
    #
    def initialize(str, player, message, players)
      super(str, player)
      @message = message
      @players = players
    end

    def call
      @players.each do |name, p| # TODO player change name
        if (p.protocol != LoginCSA::PROTOCOL)
          p.write_safe(sprintf("##[CHAT][%s] %s\n", @player.name, @message)) 
        end
      end
      return :continue
    end
  end

  # Command of LIST
  #
  class ListCommand < Command

    # games array of [game_id, game]
    #
    def initialize(str, player, games)
      super(str, player)
      @games = games
    end

    def call
      buf = Array::new
      @games.each do |id, game|
        buf.push(sprintf("##[LIST] %s\n", id))
      end
      buf.push("##[LIST] +OK\n")
      @player.write_safe(buf.join)
      return :continue
    end
  end

  # Command of WHO
  #
  class WhoCommand < Command

    # players array of [[name, player]]
    #
    def initialize(str, player, players)
      super(str, player)
      @players = players
    end

    def call
      buf = Array::new
      @players.each do |name, p|
        buf.push(sprintf("##[WHO] %s\n", p.to_s))
      end
      buf.push("##[WHO] +OK\n")
      @player.write_safe(buf.join)
      return :continue
    end
  end

  # Command of LOGOUT
  #
  class LogoutCommand < Command
    def initialize(str, player)
      super
    end

    def call
      @player.status = "connected"
      @player.write_safe("LOGOUT:completed\n")
      return :return
    end
  end

  # Command of CHALLENGE
  #
  class ChallengeCommand < Command
    def initialize(str, player)
      super
    end

    def call
      # This command is only available for CSA's official testing server.
      # So, this means nothing for this program.
      @player.write_safe("CHALLENGE ACCEPTED\n")
      return :continue
    end
  end

  # Command for a space
  #
  class SpaceCommand < Command
    def initialize(str, player)
      super
    end

    def call
      ## ignore null string
      return :continue
    end
  end

  # Command for an error
  #
  class ErrorCommand < Command
    def initialize(str, player, msg=nil)
      super(str, player)
      @msg = msg || "unknown command"
    end
    attr_reader :msg

    def call
      cmd = @str.chomp
      # Aim to hide a possible password
      cmd.gsub!(/LOGIN\s*(\w+)\s+.*/i, 'LOGIN \1...')
      @msg = "##[ERROR] %s: %s\n" % [@msg, cmd]
      @player.write_safe(@msg)
      log_error(@msg)
      return :continue
    end
  end

  #
  #
  class SetBuoyCommand < Command

    def initialize(str, player, game_name, moves, count)
      super(str, player)
      @game_name = game_name
      @moves     = moves
      @count     = count
    end

    def call
      unless (Buoy.game_name?(@game_name))
        @player.write_safe(sprintf("##[ERROR] wrong buoy game name: %s\n", @game_name))
        log_error "Received a wrong buoy game name: %s from %s." % [@game_name, @player.name]
        return :continue
      end
      buoy = Buoy.new
      unless buoy.is_new_game?(@game_name)
        @player.write_safe(sprintf("##[ERROR] duplicated buoy game name: %s\n", @game_name))
        log_error "Received duplicated buoy game name: %s from %s." % [@game_name, @player.name]
        return :continue
      end
      if @count < 1
        @player.write_safe(sprintf("##[ERROR] invalid count: %s\n", @count))
        log_error "Received an invalid count for a buoy game: %s, %s from %s." % [@count, @game_name, @player.name]
        return :continue
      end

      # check moves
      moves_array = Board::split_moves(@moves)
      board = Board.new
      begin
        board.set_from_moves(moves_array)
      rescue
        raise WrongMoves
      end

      buoy_game = BuoyGame.new(@game_name, @moves, @player.name, @count)
      buoy.add_game(buoy_game)
      @player.write_safe(sprintf("##[SETBUOY] +OK\n"))
      log_info("A buoy game was created: %s by %s" % [@game_name, @player.name])

      # if two players are waiting for this buoy game, start it
      candidates = $league.find_all_players do |player|
        player.status == "game_waiting" && 
        player.game_name == @game_name &&
        player.name != @player.name
      end
      if candidates.empty?
        log_info("No players found for a buoy game. Wait for players: %s" % [@game_name])
        return :continue 
      end
      p1 = candidates.first
      p2 = $league.find_rival(p1, @game_name)
      if p2.nil?
        log_info("No opponent found for a buoy game. Wait for the opponent: %s by %s" % [@game_name, p1.name])
        return :continue
      elsif p2.instance_of?(Symbol)  
        # An error happened. rival is not a player instance, but an error
        # symobl that must be returned to the main routine immediately.
        return p2
      end
      # found two players: p1 and p2
      log_info("Starting a buoy game: %s with %s and %s" % [@game_name, p1.name, p2.name])
      buoy.decrement_count(buoy_game)
      game = Game::new(@game_name, p1, p2, board)
      return :continue

    rescue WrongMoves => e
      @player.write_safe(sprintf("##[ERROR] wrong moves: %s\n", @moves))
      log_error "Received wrong moves: %s from %s. [%s]" % [@moves, @player.name, e.message]
      return :continue
    end
  end

  #
  #
  class DeleteBuoyCommand < Command
    def initialize(str, player, game_name)
      super(str, player)
      @game_name = game_name
    end

    def call
      buoy = Buoy.new
      buoy_game = buoy.get_game(@game_name)
      if buoy_game.instance_of?(NilBuoyGame)
        @player.write_safe(sprintf("##[ERROR] buoy game not found: %s\n", @game_name))
        log_error "Game name not found: %s by %s" % [@game_name, @player.name]
        return :continue
      end

      if buoy_game.owner != @player.name
        @player.write_safe(sprintf("##[ERROR] you are not allowed to delete a buoy game that you did not set: %s\n", @game_name))
        log_error "%s are not allowed to delete a game: %s" % [@player.name, @game_name]
        return :continue
      end

      buoy.delete_game(buoy_game)
      @player.write_safe(sprintf("##[DELETEBUOY] +OK\n"))
      log_info("A buoy game was deleted: %s" % [@game_name])
      return :continue
    end
  end

  #
  #
  class GetBuoyCountCommand < Command
    def initialize(str, player, game_name)
      super(str, player)
      @game_name = game_name
    end

    def call
      buoy = Buoy.new
      buoy_game = buoy.get_game(@game_name)
      if buoy_game.instance_of?(NilBuoyGame)
        @player.write_safe("##[GETBUOYCOUNT] -1\n")
      else
        @player.write_safe("##[GETBUOYCOUNT] %s\n" % [buoy_game.count])
      end
      @player.write_safe("##[GETBUOYCOUNT] +OK\n")
      return :continue
    end
  end

  # %%FORK <source_game> <new_buoy_game> [<nth-move>]
  # Fork a new game from the posistion where the n-th (starting from 1) move
  # of a source game is played. The new game should be a valid buoy game
  # name. The default value of n is the position where the previous position
  # of the last one.
  #
  class ForkCommand < Command
    def initialize(str, player, source_game, new_buoy_game, nth_move)
      super(str, player)
      @source_game   = source_game
      @new_buoy_game = new_buoy_game
      @nth_move      = nth_move # may be nil
    end
    attr_reader :new_buoy_game

    def decide_new_buoy_game_name
      name       = nil
      total_time = nil
      byo_time   = nil

      if @source_game.split("+").size >= 2 &&
         /^([^-]+)-(\d+)-(\d+F?)/ =~ @source_game.split("+")[1]
        name       = $1
        total_time = $2
        byo_time   = $3
      end
      if name == nil || total_time == nil || byo_time == nil
        @player.write_safe(sprintf("##[ERROR] wrong source game name to make a new buoy game name: %s\n", @source_game))
        log_error "Received a wrong source game name to make a new buoy game name: %s from %s." % [@source_game, @player.name]
        return :continue
      end
      @new_buoy_game = "buoy_%s_%d-%s-%s" % [name, @nth_move, total_time, byo_time]
      @player.write_safe(sprintf("##[FORK]: new buoy game name: %s\n", @new_buoy_game))
      @player.write_safe("##[FORK] +OK\n")
    end

    def call
      game = $league.games[@source_game]
      unless game
        @player.write_safe(sprintf("##[ERROR] wrong source game name: %s\n", @source_game))
        log_error "Received a wrong source game name: %s from %s." % [@source_game, @player.name]
        return :continue
      end

      moves = game.read_moves # [["+7776FU","T2"],["-3334FU","T5"]]
      @nth_move = moves.size - 1 unless @nth_move
      if @nth_move > moves.size or @nth_move < 1
        @player.write_safe(sprintf("##[ERROR] number of moves to fork is out of range: %s.\n", moves.size))
        log_error "Number of moves to fork is out of range: %s [%s]" % [@nth_move, @player.name]
        return :continue
      end
      new_moves_str = ""
      moves[0...@nth_move].each do |m|
        new_moves_str << m.join(",")
      end

      unless @new_buoy_game
        decide_new_buoy_game_name
      end

      buoy_cmd = SetBuoyCommand.new(@str, @player, @new_buoy_game, new_moves_str, 1)
      return buoy_cmd.call
    end
  end

end # module ShogiServer
