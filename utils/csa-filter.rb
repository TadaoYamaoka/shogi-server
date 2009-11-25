#!/usr/bin/ruby
# This program filters CSA files. For example, if you want only CSA files
# played by GPS vs Bonanza,
#   $ ./csa-filter.rb --players gps-l,bonanza some_dir
# you will see such files under the some_dir directory.
#
# Author::    Daigo Moriwaki <daigo at debian dot org>
# Copyright:: Copyright (C) 2006-2008  Daigo Moriwaki <daigo at debian dot org>
#
# $Id$
#
#--
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
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#++

require 'time'
require 'pathname'
require 'getoptlong'
require 'nkf'

class CsaFileReader
  WIN_MARK  = "win"
  LOSS_MARK = "lose"
  DRAW_MARK = "draw"

  attr_reader :file_name
  attr_reader :str
  attr_reader :black_name, :white_name
  attr_reader :black_id, :white_id
  attr_reader :winner, :loser
  attr_reader :state
  attr_reader :start_time, :end_time

  def initialize(file_name)
    @file_name = file_name
    grep
  end

  def grep
    @str = File.open(@file_name, "r:Shift_JIS:EUC-JP").read


    if /^N\+(.*)$/ =~ @str then @black_name = $1.strip end
    if /^N\-(.*)$/ =~ @str then @white_name = $1.strip end
    if /^'summary:(.*)$/ =~ @str
      @state, p1, p2 = $1.split(":").map {|a| a.strip}    
      return if @state == "abnormal"
      p1_name, p1_mark = p1.split(" ")
      p2_name, p2_mark = p2.split(" ")
      if p1_name == @black_name
        @black_name, black_mark = p1_name, p1_mark
        @white_name, white_mark = p2_name, p2_mark
      elsif p2_name == @black_name
        @black_name, black_mark = p2_name, p2_mark
        @white_name, white_mark = p1_name, p1_mark
      else
        raise "Never reach!: #{black} #{white} #{p3} #{p2}"
      end
    end
    if /^\$START_TIME:(.*)$/ =~ @str
      @start_time = Time.parse($1.strip)
    end
    if /^'\$END_TIME:(.*)$/ =~ @str
      @end_time = Time.parse($1.strip)
    end
    if /^'rating:(.*)$/ =~ @str
      black_id, white_id = $1.split(":").map {|a| a.strip}
      @black_id = identify_id(black_id)
      @white_id = identify_id(white_id)
      if @black_id && @white_id && (@black_id != @white_id) &&
         @black_mark && @white_mark
        if black_mark == WIN_MARK && white_mark == LOSS_MARK
          @winner, @loser = @black_id, @white_id
        elsif black_mark == LOSS_MARK && white_mark == WIN_MARK
          @winner, @loser = @white_id, @black_id
        elsif black_mark == DRAW_MARK && white_mark == DRAW_MARK
          @winner, @loser = nil, nil
        else
          raise "Never reached!"
        end
      end
    end
  end

  def movetimes
    ret = []
    @str.gsub(%r!^T(\d+)!) do |match|
      ret << $1.to_i
    end
    return ret
  end

  def to_s
    return "Summary: #{@file_name}\n" +
           "BlackName #{@black_name}, WhiteName #{@white_name}\n" +
           "BlackId #{@black_id}, WhiteId #{@white_id}\n" +
           "Winner #{@winner}, Loser #{@loser}\n"    +
           "Start #{@start_time}, End #{@end_time}\n"
  end

  def identify_id(id)
    if /@NORATE\+/ =~ id # the player having @NORATE in the name should not be rated
      return nil
    end
    id.gsub(/@.*?\+/,"+")
  end
end


if $0 == __FILE__
  def usage
    puts "Usage: #{$0} [OPTIONS] dir [...]"
    puts "Options:"
    puts "  --players player_a,player_b  select games of the player_a vs the player_b"
    puts "  --black player               select games of which the player is Black"
    puts "  --white player               select games of which the player is White"
    exit 1
  end

  usage if ARGV.empty?

  parser = GetoptLong.new(
             ['--black',   GetoptLong::REQUIRED_ARGUMENT],
             ['--white',   GetoptLong::REQUIRED_ARGUMENT],
             ['--players', GetoptLong::REQUIRED_ARGUMENT]
           )
  begin
    parser.each_option do |name, arg|
      eval "$OPT_#{name.sub(/^--/, '').gsub(/-/, '_').upcase} = '#{arg}'"
    end
  rescue
    usage
  end
  
  while dir = ARGV.shift
    Dir.glob(File.join(dir, "**", "*.csa")).each do |file|
      csa = CsaFileReader.new(file)

      next unless csa.black_id && csa.white_id

      if $OPT_PLAYERS
        players = $OPT_PLAYERS.split(",")
        unless (csa.black_id.downcase.index(players[0].downcase) == 0 &&
                csa.white_id.downcase.index(players[1].downcase) == 0) ||
               (csa.black_id.downcase.index(players[1].downcase) == 0 &&
                csa.white_id.downcase.index(players[0].downcase) == 0)
          next
        end
      end
      
      if $OPT_BLACK
        next unless csa.black_id.downcase.index($OPT_BLACK.downcase) == 0
      end
      if $OPT_WHITE
        next unless csa.white_id.downcase.index($OPT_WHITE.downcase) == 0
      end
      puts csa.file_name
    end
  end
end
