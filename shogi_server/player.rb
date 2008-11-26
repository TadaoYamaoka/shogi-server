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

module ShogiServer # for a namespace

class BasicPlayer
  def initialize
    @player_id = nil
    @name = nil
    @password = nil
    @rate = 0
    @win  = 0
    @loss = 0
    @last_game_win = false
  end

  # Idetifier of the player in the rating system
  attr_accessor :player_id

  # Name of the player
  attr_accessor :name
  
  # Password of the player, which does not include a trip
  attr_accessor :password

  # Score in the rating sysem
  attr_accessor :rate

  # Number of games for win and loss in the rating system
  attr_accessor :win, :loss
  
  # Group in the rating system
  attr_accessor :rating_group

  # Last timestamp when the rate was modified
  attr_accessor :modified_at

  # Whether win the previous game or not
  attr_accessor :last_game_win

  def modified_at
    @modified_at || Time.now
  end

  def rate=(new_rate)
    if @rate != new_rate
      @rate = new_rate
      @modified_at = Time.now
    end
  end

  def rated?
    @player_id != nil
  end

  def last_game_win?
    return @last_game_win
  end

  def simple_player_id
    if @trip
      simple_name = @name.gsub(/@.*?$/, '')
      "%s+%s" % [simple_name, @trip[0..8]]
    else
      @name
    end
  end

  ##
  # Parses str in the LOGIN command, sets up @player_id and @trip
  #
  def set_password(str)
    if str && !str.empty?
      @password = str.strip
      @player_id   = "%s+%s" % [@name, Digest::MD5.hexdigest(@password)]
    else
      @player_id = @password = nil
    end
  end
end


class Player < BasicPlayer
  WRITE_THREAD_WATCH_INTERVAL = 20 # sec
  def initialize(str, socket, eol=nil)
    super()
    @socket = socket
    @status = "connected"       # game_waiting -> agree_waiting -> start_waiting -> game -> finished

    @protocol = nil             # CSA or x1
    @eol = eol || "\m"          # favorite eol code
    @game = nil
    @game_name = ""
    @mytime = 0                 # set in start method also
    @sente = nil
    @socket_buffer = []
    @main_thread = Thread::current
    @write_queue = ShogiServer::TimeoutQueue.new(WRITE_THREAD_WATCH_INTERVAL)
    @player_logger = nil
    start_write_thread
  end

  attr_accessor :socket, :status
  attr_accessor :protocol, :eol, :game, :mytime, :game_name, :sente
  attr_accessor :main_thread
  attr_reader :socket_buffer
  
  def setup_logger(dir)
    log_file = File.join(dir, "%s.log" % [simple_player_id])
    @player_logger = Logger.new(log_file, 'daily')
    @player_logger.formatter = ShogiServer::Formatter.new
    @player_logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO  
    @player_logger.datetime_format = "%Y-%m-%d %H:%M:%S"
  end

  def log(level, direction, message)
    return unless @player_logger
    str = message.chomp
    case direction
      when :in
        str = "IN: %s" % [str]
      when :out
        str = "OUT: %s" % [str]
      else
        str = "UNKNOWN DIRECTION: %s %s" % [direction, str]
    end
    case level
      when :debug
        @player_logger.debug(str)
      when :info
        @player_logger.info(str)
      when :warn
        @player_logger.warn(str)
      when :error
        @player_logger.error(str)
      else
        @player_logger.debug("UNKNOWN LEVEL: %s %s" % [level, str])
    end
  rescue Exception => ex
    log_error("#{ex.class}: #{ex.message}\n\t#{ex.backtrace[0]}")
  end

  def kill
    log_message(sprintf("user %s killed", @name))
    if (@game)
      @game.kill(self)
    end
    finish
    Thread::kill(@main_thread)  if @main_thread
    Thread::kill(@write_thread) if @write_thread
  end

  def finish
    if (@status != "finished")
      @status = "finished"
      log_message(sprintf("user %s finish", @name))    
      begin
        log_debug("Terminating %s's write thread..." % [@name])
        if @write_thread && @write_thread.alive?
          write_safe(nil)
          @write_thread.join
        end
        @player_logger.close if @player_logger
        log_debug("done.")
      rescue
        log_message(sprintf("user %s finish failed", @name))    
      end
    end
  end

  def start_write_thread
    @write_thread = Thread.start do
      Thread.pass
      while !@socket.closed?
        begin
          str = @write_queue.deq
          if (str == nil)
            log_debug("%s's write thread terminated" % [@name])
            break
          end
          if (str == :timeout)
            log_debug("%s's write queue timed out. Try again..." % [@name])
            next
          end

          if r = select(nil, [@socket], nil, 20)
            r[1].first.write(str)
            log(:info, :out, str)
          else
            log_error("Gave a try to send a message to #{@name}, but it timed out.")
            break
          end
        rescue Exception => ex
          log_error("Failed to send a message to #{@name}. #{ex.class}: #{ex.message}\t#{ex.backtrace[0]}")
          break
        end
      end # while loop
      log_error("%s's socket closed." % [@name]) if @socket.closed?
      log_message("At least %d messages are not sent to the client." % 
                  [@write_queue.get_messages.size])
    end # thread
  end

  #
  # Note that sending a message is included in the giant lock.
  #
  def write_safe(str)
    @write_queue.enq(str)
  end

  def to_s
    if ["game_waiting", "start_waiting", "agree_waiting", "game"].include?(status)
      if (@sente)
        return sprintf("%s %s %s %s +", rated? ? @player_id : @name, @protocol, @status, @game_name)
      elsif (@sente == false)
        return sprintf("%s %s %s %s -", rated? ? @player_id : @name, @protocol, @status, @game_name)
      elsif (@sente == nil)
        return sprintf("%s %s %s %s *", rated? ? @player_id : @name, @protocol, @status, @game_name)
      end
    else
      return sprintf("%s %s %s", rated? ? @player_id : @name, @protocol, @status)
    end
  end

  def run(csa_1st_str=nil)
    while ( csa_1st_str || 
            str = gets_safe(@socket, (@socket_buffer.empty? ? Default_Timeout : 1)) )
      log(:info, :in, str) if str && str.instance_of?(String) 
      $mutex.lock
      begin
        if !@write_thread.alive?
          log_error("%s's write thread is dead. Aborting..." % [@name])
          return
        end
        if (@game && @game.turn?(self))
          @socket_buffer << str
          str = @socket_buffer.shift
        end
        log_debug("%s (%s)" % [str, @socket_buffer.map {|a| String === a ? a.strip : a }.join(",")])

        if (csa_1st_str)
          str = csa_1st_str
          csa_1st_str = nil
        end

        if (@status == "finished")
          return
        end
        str.chomp! if (str.class == String) # may be strip! ?
        case str 
        when "" 
          # Application-level protocol for Keep-Alive
          # If the server gets LF, it sends back LF.
          # 30 sec rule (client may not send LF again within 30 sec) is not implemented yet.
          write_safe("\n")
        when /^[\+\-][^%]/
          if (@status == "game")
            array_str = str.split(",")
            move = array_str.shift
            additional = array_str.shift
            if /^'(.*)/ =~ additional
              comment = array_str.unshift("'*#{$1.toeuc}")
            end
            s = @game.handle_one_move(move, self)
            @game.fh.print("#{Kconv.toeuc(comment.first)}\n") if (comment && comment.first && !s)
            return if (s && @protocol == LoginCSA::PROTOCOL)
          end
        when /^%[^%]/, :timeout
          if (@status == "game")
            s = @game.handle_one_move(str, self)
            return if (s && @protocol == LoginCSA::PROTOCOL)
          end
        when :exception
          log_error("Failed to receive a message from #{@name}.")
          return
        when /^REJECT/
          if (@status == "agree_waiting")
            @game.reject(@name)
            return if (@protocol == LoginCSA::PROTOCOL)
          else
            write_safe(sprintf("##[ERROR] you are in %s status. AGREE is valid in agree_waiting status\n", @status))
          end
        when /^AGREE/
          if (@status == "agree_waiting")
            @status = "start_waiting"
            if ((@game.sente.status == "start_waiting") &&
                (@game.gote.status == "start_waiting"))
              @game.start
              @game.sente.status = "game"
              @game.gote.status = "game"
            end
          else
            write_safe(sprintf("##[ERROR] you are in %s status. AGREE is valid in agree_waiting status\n", @status))
          end
        when /^%%SHOW\s+(\S+)/
          game_id = $1
          if (LEAGUE.games[game_id])
            write_safe(LEAGUE.games[game_id].show.gsub(/^/, '##[SHOW] '))
          end
          write_safe("##[SHOW] +OK\n")
        when /^%%MONITORON\s+(\S+)/
          game_id = $1
          if (LEAGUE.games[game_id])
            LEAGUE.games[game_id].monitoron(self)
            write_safe(LEAGUE.games[game_id].show.gsub(/^/, "##[MONITOR][#{game_id}] "))
            write_safe("##[MONITOR][#{game_id}] +OK\n")
          end
        when /^%%MONITOROFF\s+(\S+)/
          game_id = $1
          if (LEAGUE.games[game_id])
            LEAGUE.games[game_id].monitoroff(self)
          end
        when /^%%HELP/
          write_safe(
            %!##[HELP] available commands "%%WHO", "%%CHAT str", "%%GAME game_name +", "%%GAME game_name -"\n!)
        when /^%%RATING/
          players = LEAGUE.rated_players
          players.sort {|a,b| b.rate <=> a.rate}.each do |p|
            write_safe("##[RATING] %s \t %4d @%s\n" % 
                       [p.simple_player_id, p.rate, p.modified_at.strftime("%Y-%m-%d")])
          end
          write_safe("##[RATING] +OK\n")
        when /^%%VERSION/
          write_safe "##[VERSION] Shogi Server revision #{Revision}\n"
          write_safe("##[VERSION] +OK\n")
        when /^%%GAME\s*$/
          if ((@status == "connected") || (@status == "game_waiting"))
            @status = "connected"
            @game_name = ""
          else
            write_safe(sprintf("##[ERROR] you are in %s status. GAME is valid in connected or game_waiting status\n", @status))
          end
        when /^%%(GAME|CHALLENGE)\s+(\S+)\s+([\+\-\*])\s*$/
          command_name = $1
          game_name = $2
          my_sente_str = $3
          if (! Login::good_game_name?(game_name))
            write_safe(sprintf("##[ERROR] bad game name\n"))
            next
          elsif ((@status == "connected") || (@status == "game_waiting"))
            ## continue
          else
            write_safe(sprintf("##[ERROR] you are in %s status. GAME is valid in connected or game_waiting status\n", @status))
            next
          end

          rival = nil
          if (League::Floodgate.game_name?(game_name))
            if (my_sente_str != "*")
              write_safe(sprintf("##[ERROR] You are not allowed to specify TEBAN %s for the game %s\n", my_sente_str, game_name))
              next
            end
            @sente = nil
          else
            if (my_sente_str == "*")
              rival = LEAGUE.get_player("game_waiting", game_name, nil, self) # no preference
            elsif (my_sente_str == "+")
              rival = LEAGUE.get_player("game_waiting", game_name, false, self) # rival must be gote
            elsif (my_sente_str == "-")
              rival = LEAGUE.get_player("game_waiting", game_name, true, self) # rival must be sente
            else
              ## never reached
              write_safe(sprintf("##[ERROR] bad game option\n"))
              next
            end
          end

          if (rival)
            @game_name = game_name
            if ((my_sente_str == "*") && (rival.sente == nil))
              if (rand(2) == 0)
                @sente = true
                rival.sente = false
              else
                @sente = false
                rival.sente = true
              end
            elsif (rival.sente == true) # rival has higher priority
              @sente = false
            elsif (rival.sente == false)
              @sente = true
            elsif (my_sente_str == "+")
              @sente = true
              rival.sente = false
            elsif (my_sente_str == "-")
              @sente = false
              rival.sente = true
            else
              ## never reached
            end
            Game::new(@game_name, self, rival)
          else # rival not found
            if (command_name == "GAME")
              @status = "game_waiting"
              @game_name = game_name
              if (my_sente_str == "+")
                @sente = true
              elsif (my_sente_str == "-")
                @sente = false
              else
                @sente = nil
              end
            else                # challenge
              write_safe(sprintf("##[ERROR] can't find rival for %s\n", game_name))
              @status = "connected"
              @game_name = ""
              @sente = nil
            end
          end
        when /^%%CHAT\s+(.+)/
          message = $1
          LEAGUE.players.each do |name, player|
            if (player.protocol != LoginCSA::PROTOCOL)
              player.write_safe(sprintf("##[CHAT][%s] %s\n", @name, message)) 
            end
          end
        when /^%%LIST/
          buf = Array::new
          LEAGUE.games.each do |id, game|
            buf.push(sprintf("##[LIST] %s\n", id))
          end
          buf.push("##[LIST] +OK\n")
          write_safe(buf.join)
        when /^%%WHO/
          buf = Array::new
          LEAGUE.players.each do |name, player|
            buf.push(sprintf("##[WHO] %s\n", player.to_s))
          end
          buf.push("##[WHO] +OK\n")
          write_safe(buf.join)
        when /^LOGOUT/
          @status = "connected"
          write_safe("LOGOUT:completed\n")
          return
        when /^CHALLENGE/
          # This command is only available for CSA's official testing server.
          # So, this means nothing for this program.
          write_safe("CHALLENGE ACCEPTED\n")
        when /^\s*$/
          ## ignore null string
        else
          msg = "##[ERROR] unknown command %s\n" % [str]
          write_safe(msg)
          log_error(msg)
        end
      ensure
        $mutex.unlock
      end
    end # enf of while
  end # def run
end # class

end # ShogiServer
