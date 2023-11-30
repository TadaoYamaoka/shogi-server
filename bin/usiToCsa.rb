#!/usr/bin/env ruby
# $Id$
#
# Author:: Daigo Moriwaki
# Homepage:: http://sourceforge.jp/projects/shogi-server/
#
#--
# Copyright (C) 2013 Daigo Moriwaki (daigo at debian dot org)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#++
#
#

$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), ".."))
require 'shogi_server'
require 'logger'
require 'socket'

# Global variables

$options = nil
$logger  = nil   # main log IO
$engine  = nil   # engine IO
$server  = nil   # shogi server IO
$bridge_state = nil

def usage
    print <<EOM
NAME
        #{File.basename($0)} - Brige program for a USI engine to connect to a CSA shogi server

SYNOPSIS
        #{File.basename($0)} [OPTIONS]... path_to_usi_engine

DESCRIPTION
        Bridge program for a USI engine to connect to a CSA shogi server

OPTIONS
        hash
                hash size in MB
        host
                a host name to connect to a CSA server
        id
                player id for a CSA server
        keep-alive
                Interval in seconds to send a keep-alive packet to the server. [default 0]
                Disabled if it is 0.
        log-dir
                directory to put log files
        margin-msec
                margin time [milliseconds] for byoyomi
        options
                option key and value for a USI engine. Use dedicated options
                for USI_Ponder and USI_Hash.
                ex --options "key_a=value_a,key_b=value_b"
        password
                password for a CSA server
        ponder
                enble ponder
        port
                a port number to connect to a CSA server. 4081 is often used.

EXAMPLES

LICENSE
        GPL versoin 2 or later

SEE ALSO

REVISION
        #{ShogiServer::Revision}

EOM
end

# Parse command line options. Return a hash containing the option strings
# where a key is the option name without the first two slashes. For example,
# {"pid-file" => "foo.pid"}.
#
def parse_command_line
  options = Hash::new
  parser = GetoptLong.new(
    ["--hash",        GetoptLong::REQUIRED_ARGUMENT],
    ["--host",        GetoptLong::REQUIRED_ARGUMENT],
    ["--id",          GetoptLong::REQUIRED_ARGUMENT],
    ["--keep-alive",  GetoptLong::REQUIRED_ARGUMENT],
    ["--log-dir",     GetoptLong::REQUIRED_ARGUMENT],
    ["--margin-msec", GetoptLong::REQUIRED_ARGUMENT],
    ["--options",     GetoptLong::REQUIRED_ARGUMENT],
    ["--password",    GetoptLong::REQUIRED_ARGUMENT],
    ["--ponder",      GetoptLong::NO_ARGUMENT],
    ["--port",        GetoptLong::REQUIRED_ARGUMENT],
    ["--floodgate",   GetoptLong::NO_ARGUMENT],
    ["--handicap-msec", GetoptLong::REQUIRED_ARGUMENT])
  parser.quiet = true
  begin
    parser.each_option do |name, arg|
      name.sub!(/^--/, '')
      name.sub!(/-/,'_')
      options[name.to_sym] = arg.dup
    end
  rescue
    usage
    raise parser.error_message
  end

  # Set default values
  options[:hash]        ||= ENV["HASH"] || 256
  options[:hash]        = options[:hash].to_i
  options[:host]        ||= ENV["HOST"] || "wdoor.c.u-tokyo.ac.jp"
  options[:margin_msec] ||= ENV["MARGIN_MSEC"] || 2500
  options[:margin_msec] = options[:margin_msec].to_i
  options[:id]          ||= ENV["ID"]
  options[:keep_alive]  ||= ENV["KEEP_ALIVE"] || 0
  options[:keep_alive]  = options[:keep_alive].to_i
  options[:log_dir]     ||= ENV["LOG_DIR"] || "."
  options[:password]    ||= ENV["PASSWORD"]
  options[:ponder]      ||= ENV["PONDER"] || false
  options[:port]        ||= ENV["PORT"] || 4081
  options[:port]        = options[:port].to_i
  options[:floodgate]   ||= ENV["FLOODGATE"] || false
  options[:handicap_msec] ||= ENV["HANDICAP_MSEC"] || 0
  options[:handicap_msec] = options[:handicap_msec].to_i

  return options
end

# Check command line options.
# If any of them is invalid, exit the process.
#
def check_command_line
  if (ARGV.length < 1)
    usage
    exit 2
  end

  $options[:engine_path] = ARGV.shift
end

class BridgeFormatter < ::Logger::Formatter
  def initialize
    super
    @datetime_format = "%Y-%m-%dT%H:%M:%S.%6N"
  end

  def call(severity, time, progname, msg)
    str = msg2str(msg)
    str.strip! if str
    %!%s [%s]\n%s\n\n! % [format_datetime(time), severity, str]
  end
end

def setup_logger(log_file)
  logger = ShogiServer::Logger.new(log_file, 'daily')
  logger.formatter = BridgeFormatter.new
  logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO  
  return logger
end

def log_engine_recv(msg)
  $logger.info ">>> RECV LOG_ENGINE\n#{msg.gsub(/^/,"    ")}"
end

def log_engine_send(msg)
  $logger.info "<<< SEND LOG_ENGINE\n#{msg.gsub(/^/,"    ")}"
end

def log_server_recv(msg)
  $logger.info ">>> RECV LOG_SERVER\n#{msg.gsub(/^/,"    ")}"
end

def log_server_send(msg)
  $logger.info "<<< SEND LOG_SERVER\n#{msg.gsub(/^/,"    ")}"
end

def log_info(msg, sout=true)
  $stdout.puts msg if sout
  $logger.info msg
end

def log_error(msg)
  $stdout.puts msg
  $logger.error msg
end

# Holds the state of this Bridge program
#
class BridgeState
  attr_reader :state

  %W!CONNECTED GAME_WAITING_CSA AGREE_WAITING_CSA GAME_CSA GAME_END PONDERING!.each do |s|
    class_eval <<-EVAL, __FILE__, __LINE__ + 1
      def #{s}?
        return @state == :#{s}
      end

      def assert_#{s}
        unless #{s}?
          throw "Illegal state: #{@state}"
        end
      end
    EVAL
  end

  def initialize
    @state      = :GAME_WAITING_CSA
    @csaToUsi   = ShogiServer::Usi::CsaToUsi.new
    @usiToCsa   = ShogiServer::Usi::UsiToCsa.new
    @last_server_send_time = Time.now

    @game_id    = nil
    @side       = nil    # my side; true for Black, false for White
    @black_time = nil    # milliseconds
    @white_time = nil    # milliseconds
    @byoyomi    = nil    # milliseconds
    @increment  = 0      # milliseconds (increment非対応のshogi-serverとの互換性のために初期値は0にしておく)

    @depth       = nil
    @cp          = nil
    @pv          = nil
    @ponder_move = nil
  end

  def next_turn
    @depth      = nil
    @cp         = nil
    @pv         = nil
    @ponder_move = nil
  end

  def update_last_server_send_time
    @last_server_send_time = Time.now
  end

  def too_quiet?
    if $options[:keep_alive] <= 0
      return false
    end

    return $options[:keep_alive] < (Time.now - @last_server_send_time)
  end

  def transite(state)
    @state   = state
  end

  def byoyomi
    if (@byoyomi - $options[:margin_msec]) > 0
      return (@byoyomi - $options[:margin_msec])
    else
      return @byoyomi
    end
  end

  def do_sever_recv
    case $bridge_state.state
    when :CONNECTED
    when :GAME_WAITING_CSA
      event_game_summary
    when :AGREE_WAITING_CSA
      event_game_start
    when :GAME_CSA, :PONDERING
      event_server_recv
    when :GAME_END
    end
  end

  def do_engine_recv
    case $bridge_state.state
    when :CONNECTED
    when :GAME_WAITING_CSA
    when :AGREE_WAITING_CSA
    when :GAME_CSA, :PONDERING
      event_engine_recv
    when :GAME_END
    end
  end

  def parse_game_summary(str)
    str.each_line do |line|
      case line.strip
      when /^Your_Turn:([\+\-])/
        case $1
        when "+"
          @side = true
        when "-"
          @side = false
        end
      when /^Total_Time:(\d+)/
        @black_time = $1.to_i * 1000 - $options[:handicap_msec]
        @white_time = $1.to_i * 1000
      when /^Byoyomi:(\d+)/
        @byoyomi = $1.to_i * 1000
      when /^Increment:(\d+)/
        @increment = $1.to_i * 1000
      when /^([\+\-]\d{4}\w{2}),T(\d+)/
        csa  = $1
        state1, usi = @csaToUsi.next(csa)
        @usiToCsa.next(usi)
      end
    end

    if [@side, @black_time, @white_time].include?(nil)
      throw "Bad game summary: str"
    end
  end

  def event_game_summary
    assert_GAME_WAITING_CSA

    str = recv_until($server, /^END Game_Summary/)
    log_server_recv str

    parse_game_summary(str)

    server_puts "AGREE"
    transite :AGREE_WAITING_CSA
  end

  def event_game_start
    assert_AGREE_WAITING_CSA

    str = $server.gets
    return if str.nil? || str.strip.empty?
    log_server_recv str

    case str
    when /^START:(.*)/
      @game_id = $1
      @time_turn_start = Time.now
      log_info "game crated #@game_id"
      
      next_turn
      engine_puts "usinewgame"
      if (@csaToUsi.usi_moves.length % 2 == 0) == @side
        engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}"
        if @increment > 0 then
          engine_puts "go btime #@black_time wtime #@white_time binc #@increment winc #@increment"
        else
          engine_puts "go btime #@black_time wtime #@white_time byoyomi #{byoyomi()}"
        end
      end
      transite :GAME_CSA
    when /^REJECT:(.*)/
      log_info "game rejected."
      transite :GAME_END
    else         
      throw "Bad message in #{@state}: #{str}" 
    end
  end

  def handle_one_move(usi)
    state, csa  = @usiToCsa.next(usi)
    # TODO state :normal
    if state != :normal
      log_error "Found bad move #{usi} (#{csa}): #{state}"
    end
    if $options[:floodgate]
      c = comment()
      unless c.empty?
        csa += ",#{c}"
      end
    end
    server_puts csa
  end

  def event_engine_recv
    unless [:GAME_CSA, :PONDERING].include?(@state)
      throw "Bad state at event_engine_recv: #@state"
    end

    str = $engine.gets
    return if str.nil? || str.strip.empty?
    log_engine_recv str

    case str.strip
    when /^bestmove\s+resign/
      if PONDERING?
        log_info "Ignore bestmove after 'stop'", false
        # Trigger the next turn
        transite :GAME_CSA
        next_turn
        if @increment > 0 then
          engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}\ngo btime #@black_time wtime #@white_time binc #@increment winc #@increment"
        else
          engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}\ngo btime #@black_time wtime #@white_time byoyomi #{byoyomi()}"
        end
      else
        server_puts "%TORYO"
      end
    when /^bestmove\swin/
      server_puts "%KACHI"
    when /^bestmove\s+(.*)/
      str = $1.strip
      
      if PONDERING?
        log_info "Ignore bestmove after 'stop'", false
        # Trigger the next turn
        transite :GAME_CSA
        next_turn
        if @increment > 0 then
          engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}\ngo btime #@black_time wtime #@white_time binc #@increment winc #@increment"
        else
          engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}\ngo btime #@black_time wtime #@white_time byoyomi #{byoyomi()}"
        end
      else
        case str
        when /^(.*)\s+ponder\s+(.*)/
          usi          = $1.strip
          @ponder_move = $2.strip

          handle_one_move(usi)

          if $options[:ponder]
            moves = @usiToCsa.usi_moves.clone
            moves << @ponder_move
            btime_tmp = @black_time
            wtime_tmp = @white_time
            estimated_consumption = (Time.now - @time_turn_start).ceil * 1000 # give a some margin by ceiling the value
            if @side then
              btime_tmp = [btime_tmp + @increment - estimated_consumption, 0].max
            else
              wtime_tmp = [wtime_tmp + @increment - estimated_consumption, 0].max
            end
            if @increment > 0 then
              engine_puts "position startpos moves #{moves.join(" ")}\ngo ponder btime #{btime_tmp} wtime #{wtime_tmp} binc #@increment winc #@increment"
            else
              engine_puts "position startpos moves #{moves.join(" ")}\ngo ponder btime #{btime_tmp} wtime #{wtime_tmp} byoyomi #{byoyomi()}"
            end
            transite :PONDERING
          end
        else
          handle_one_move(str)
        end
      end
    when /^info\s+(.*)/
      str = $1
      if /(\s+|^)depth\s(\d+)/ =~ str
        @depth = $2
      end
      if /(\s+|^)score\s+cp\s+(-?\d+)/ =~ str
        @cp = $2.to_i
        if !@side
          @cp *= -1
        end
      elsif /(\s+|^)score\s+mate\s+(-?)/ =~ str
        @cp = ($2 == "-" ? -100000 : 100000)
        if !@side
          @cp *= -1
        end
      end
      if /(\s+|^)pv\s+(.*)$/ =~str
        @pv = $2
      end
    end
  end

  def event_server_recv
    unless [:GAME_CSA, :PONDERING].include?(@state)
      throw "Bad state at event_engine_recv: #@state"
    end

    str = $server.gets
    return if str.nil? || str.strip.empty?
    log_server_recv str

    case str.strip
    when /^%TORYO,T(\d+)/
      log_info str
    when /^#(\w+)/
      s = $1
      log_info str
      if %w!WIN LOSE DRAW CENSORED!.include?(s)
        server_puts "LOGOUT"
        engine_puts "gameover #{s.downcase}"
        transite :GAME_END
      end
    when /^([\+\-]\d{4}\w{2}),T(\d+)/
      csa  = $1
      msec = $2.to_i * 1000

      if csa[0..0] == "+"
        @black_time = [@black_time + @increment - msec, 0].max
        if !@side
          @time_turn_start = Time.now
        end
      else
        @white_time = [@white_time + @increment - msec, 0].max
        if @side
          @time_turn_start = Time.now
        end
      end

      state1, usi = @csaToUsi.next(csa)

      # TODO state
      
      if csa[0..0] != (@side ? "+" : "-")
        # Recive a new move from the opponent
        state2, dummy = @usiToCsa.next(usi)

        if PONDERING?
          if usi == @ponder_move
            engine_puts "ponderhit"
            transite :GAME_CSA
            #next_turn
            # Engine keeps on thinking
          else
            engine_puts "stop"
          end
        else
          transite :GAME_CSA
          next_turn
          if @increment > 0 then
            engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}\ngo btime #@black_time wtime #@white_time binc #@increment winc #@increment"
          else
            engine_puts "position startpos moves #{@csaToUsi.usi_moves.join(" ")}\ngo btime #@black_time wtime #@white_time byoyomi #{byoyomi()}"
          end
        end
      end
    end
  end

  def comment
    if [@cp, @pv].include?(nil)
      return ""
    end

    usiToCsa = @usiToCsa.deep_copy
    pvs = @pv.split(" ")
    if usiToCsa.usi_moves.last == pvs.first
      pvs.shift
    end

    moves = []
    pvs.each do |usi|
      begin
        state, csa = usiToCsa.next(usi)
        moves << csa
      rescue
        # ignore
      end
    end
    
    if moves.empty?
      return "'* #@cp"
    else
      return "'* #@cp #{moves.join(" ")}"
    end
  end
end # class BridgeState

def recv_until(io, regexp)
  lines = []
  while line = io.gets
    #puts "=== #{line}"
    lines << line
    break if regexp =~ line
  end
  return lines.join("")
end

def engine_puts(str)
  log_engine_send str
  $engine.puts str
end

def server_puts(str)
  log_server_send str
  $server.puts str
  $bridge_state.update_last_server_send_time
end

# Start an engine process
#
def start_engine
  log_info("Starting engine...  #{$options[:engine_path]}")

  cmd = %Q!| #{$options[:engine_path]}!
  $engine = open(cmd, "w+")
  $engine.sync = true

  select(nil, [$engine], nil)
  log_engine_send "usi"
  $engine.puts "usi"
  r = recv_until $engine, /usiok/
  log_engine_recv r

  lines =  ["setoption name USI_Hash value #{$options[:hash]}"]
  lines << ["setoption name Hash value #{$options[:hash]}"] # for gpsfish
  if $options[:ponder]
    lines << "setoption name USI_Ponder value true"
    lines << "setoption name Ponder value true" # for gpsfish
  end
  if $options[:options] 
    $options[:options].split(",").each do |str|
      key, value = str.split("=")
      lines << "setoption name #{key} value #{value}"
    end
  end
  engine_puts lines.join("\n")

  log_engine_send "isready"
  $engine.puts "isready"
  r = recv_until $engine, /readyok/
  log_engine_recv r
end

# Login to the shogi server
#
def login
  log_info("Connecting to #{$options[:host]}:#{$options[:port]}...")
  begin
    $server = TCPSocket.open($options[:host], $options[:port])
    $server.sync = true
  rescue
    log_error "Failed to connect to the server"
    $server = nil
    return false
  end

  begin
    log_info("Login...  #{$options[:id]},xxxxxxxx")
    if select(nil, [$server], nil, 15)
      $server.puts "LOGIN #{$options[:id]} #{$options[:password]}"
    else
      log_error("Failed to send login message to the server")
      $server.close
      $server = nil
      return false
    end

    if select([$server], nil, nil, 15)
      line = $server.gets
      if /LOGIN:.* OK/ =~ line
        log_info(line)
      else
        log_error("Failed to login to the server")
        $server.close
        $server = nil
        return false
      end
    else
      log_error("Login attempt to the server timed out")
      $server.close
      $server = nil
    end
  rescue Exception => ex
    log_error("login_loop: #{ex.class}: #{ex.message}\n\t#{ex.backtrace[0]}")
    return false
  end

  return true
end

# MAIN LOOP
#
def main_loop
  while true
    ret, = select([$server, $engine], nil, nil, 60)
    unless ret
      # Send keep-alive
      if $bridge_state.too_quiet?
        $server.puts ""
        $bridge_state.update_last_server_send_time
      end
      next
    end

    ret.each do |io|
      case io
      when $engine
        $bridge_state.do_engine_recv
      when $server
        $bridge_state.do_sever_recv
      end
    end

    if $bridge_state.GAME_END?
      engine_puts "quit"
      log_info "game finished."
      break
    end
  end

  if $engine.nil?
    $engine.close
    $engile = nil
  end

  if $server.nil?
    $server.close
    $server = nil
  end

rescue Exception => ex
  log_error "main: #{ex.class}: #{ex.message}\n\t#{ex.backtrace.join("\n\t")}"
end

# MAIN
#
def main
  $logger = setup_logger("main.log")

  # Parse command line options
  $options = parse_command_line
  check_command_line

  # Start engine
  start_engine

  # Login to the shogi server
  if login
    $bridge_state = BridgeState.new
    log_info("Wait for a game start...")
    main_loop
  else
    exit 1
  end
end

if ($0 == __FILE__)
  STDOUT.sync = true
  STDERR.sync = true
  TCPSocket.do_not_reverse_lookup = true
  Thread.abort_on_exception = $DEBUG ? true : false

  begin
    main
  rescue Exception => ex
    if $logger
      log_error("main: #{ex.class}: #{ex.message}\n\t#{ex.backtrace[0]}")
    else
      $stderr.puts "main: #{ex.class}: #{ex.message}\n\t#{ex.backtrace[0]}"
    end
    exit 1
  end
  
  exit 0
end
