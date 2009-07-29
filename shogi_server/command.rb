require 'kconv'
require 'shogi_server'

module ShogiServer

  class Command
    # Factory method
    #
    def Command.factory(str, player)
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
      when /^\s*$/
        cmd = SpaceCommand.new(str, player)
      else
        cmd = ErrorCommand.new(str, player)
      end

      return cmd
    end

    def initialize(str, player)
      @str    = str
      @player = player
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
        additional = array_str.shift
        comment = nil
        if /^'(.*)/ =~ additional
          comment = array_str.unshift("'*#{$1.toeuc}")
        end
        s = @player.game.handle_one_move(move, @player)
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

      s = @player.game.handle_one_move(@str, @player)
      rc = :return if (s && @player.protocol == LoginCSA::PROTOCOL)

      return rc
    end

    def in_waiting_status
      rc = :continue

      if @player.game.prepared_expire?
        log_warning("#{@player.status} lasted too long. This play has been expired.")
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

  # Command of MONITORON
  #
  class MonitorOnCommand < BaseCommandForGame
    def initialize(str, player, game)
      super
    end

    def call
      if (@game)
        @game.monitoron(@player)
        @player.write_safe(@game.show.gsub(/^/, "##[MONITOR][#{@game_id}] "))
        @player.write_safe("##[MONITOR][#{@game_id}] +OK\n")
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
        @game.monitoroff(@player)
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
    end

    def call
      if (! Login::good_game_name?(@game_name))
        @player.write_safe(sprintf("##[ERROR] bad game name\n"))
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
        if (@my_sente_str == "*")
          rival = $league.get_player("game_waiting", @game_name, nil, @player) # no preference
        elsif (@my_sente_str == "+")
          rival = $league.get_player("game_waiting", @game_name, false, @player) # rival must be gote
        elsif (@my_sente_str == "-")
          rival = $league.get_player("game_waiting", @game_name, true, @player) # rival must be sente
        else
          ## never reached
          @player.write_safe(sprintf("##[ERROR] bad game option\n"))
          return :continue
        end
      end

      if (rival)
        @player.game_name = @game_name
        if ((@my_sente_str == "*") && (rival.sente == nil))
          if (rand(2) == 0)
            @player.sente = true
            rival.sente = false
          else
            @player.sente = false
            rival.sente = true
          end
        elsif (rival.sente == true) # rival has higher priority
          @player.sente = false
        elsif (rival.sente == false)
          @player.sente = true
        elsif (@my_sente_str == "+")
          @player.sente = true
          rival.sente = false
        elsif (@my_sente_str == "-")
          @player.sente = false
          rival.sente = true
        else
          ## never reached
        end
        Game::new(@player.game_name, @player, rival)
      else # rival not found
        if (@command_name == "GAME")
          @player.status = "game_waiting"
          @player.game_name = @game_name
          if (@my_sente_str == "+")
            @player.sente = true
          elsif (@my_sente_str == "-")
            @player.sente = false
          else
            @player.sente = nil
          end
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
    def initialize(str, player)
      super
    end

    def call
      msg = "##[ERROR] unknown command %s\n" % [@str]
      @player.write_safe(msg)
      log_error(msg)
      return :continue
    end
  end


end # module ShogiServer
