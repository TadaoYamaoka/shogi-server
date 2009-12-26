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

require 'shogi_server/command'

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
    @sente = nil
    @game_name = ""
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

  # true for Sente; false for Gote
  attr_accessor :sente

  # game name
  attr_accessor :game_name

  def is_human?
    return [%r!_human$!, %r!_human@!].any? do |re|
      re.match(@name)
    end
  end

  def is_computer?
    return !is_human?
  end

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
    @mytime = 0                 # set in start method also
    @socket_buffer = []
    @main_thread = Thread::current
    @write_queue = ShogiServer::TimeoutQueue.new(WRITE_THREAD_WATCH_INTERVAL)
    @player_logger = nil
    start_write_thread
  end

  attr_accessor :socket, :status
  attr_accessor :protocol, :eol, :game, :mytime
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

        cmd = ShogiServer::Command.factory(str, self)
        case cmd.call
        when :return
          return
        when :continue
          # do nothing
        else
          # TODO never reach
        end

      ensure
        $mutex.unlock
      end
    end # enf of while
  end # def run
end # class

end # ShogiServer
