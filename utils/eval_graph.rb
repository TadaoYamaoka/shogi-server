#!/usr/bin/ruby
# This generates graphs of evaluation values from comments in CSA files.
# Ruby libraries that are required: 
# * RubyGems: http://rubyforge.org/projects/rubygems/
# * rgplot:   http://rubyforge.org/projects/rgplot/
# OS librariles that is required:
# * Gnuplot:  http://www.gnuplot.info/
#   * On Debian, $ sudo apt-get install gnuplot
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

require 'pathname'
require 'getoptlong'
require 'rubygems'
require 'gnuplot'

def to_svg_file(csa_file)
  "#{csa_file}.svg"
end

def reformat_svg(str)
  str.gsub(%r!<svg.*?>!m, <<-END) 
<svg viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
END
end

# Parse play time from the game_name, then return it. If the game_name is
# not valid, return 0.
#
def play_time(game_name)
  if /.*?\+.*?\-(\d*?)\-/ =~ game_name
    return $1.to_i
  end
  return 0  
end

module EvalGraph
  def parse_comment(str)
    return nil unless str
    str.strip!
    items = str.split(" ")
    if items.size > 0
      return items[0]
    else
      return nil
    end
  end
  module_function :parse_comment
  
  class Player
    attr_accessor :theOther
    attr_reader   :name, :comments, :start_time
    
    # type is '+' or '-'
    def initialize(type)
      @comments = []
      @times = []
      @type = type
      @regexp_move    = Regexp.new("^\\#{@type}\\d{4}\\w{2}")
      @regexp_name    = Regexp.new("^N\\#{@type}(.*)")
      @regexp_time    = Regexp.new(/^T(\d+)/)
      @regexp_comment = Regexp.new(/^'\*\*(.*)/)
      @flag = false
      @name = nil
    end

    def reset
      if @flag
        @comments << nil
      end
      @flag = false
    end

    def <<(comment)
      case comment
      when @regexp_move
        @flag = true
        @theOther.reset
      when @regexp_time
        if @flag
          @times << $1.to_i
        end
      when @regexp_comment
        if @flag
          @comments << EvalGraph::parse_comment($1)
          @flag = false
        end
      when @regexp_name
        @name = $1
      when /\$START_TIME:(.*)/
        @start_time = $1
      end
    end

    # Return times for each move which the player played. 
    # return[0] is the initial play_time.
    #
    def time_values(y_max, play_time)
      consume = play_time
      values = []
      values << 1.0*y_max/play_time*consume
      @times.each do |t|
        if consume == 0
          break
        end
        consume -= t
        if consume < 0
          consume = 0
        end
        values << 1.0*y_max/play_time*consume
      end
      return values
    end
  end # Player

  class Black < Player
    def name
      @name ? "#{@name} (B)" : "black"
    end

    # Gluplot can not show nil vlaues so that a return value has to contain
    # [[0], [0]] at least.
    def eval_values
      moves = []
      comments.each_with_index do |c, i|
        moves << i*2 + 1 if c
      end
      moves.unshift 0
      [moves, comments.compact.unshift(0)]
    end

    # Return moves and times. For example, [[0,1,3], [900, 899, 898]]
    def time_values(y_max, play_time)
      values = super
      moves = [0]
      return [moves, values] if values.size <= 1

      i = 1
      values[1, values.size-1].each do |v|
        moves << i
        i += 2
      end
      return [moves, values]
    end
  end # Black

  class White < Player
    def name
      @name ? "#{@name} (W)" : "white"
    end

    def eval_values
      moves = []
      comments.each_with_index do |c, i|
        moves << i*2 if c
      end
      moves.unshift 0
      [moves, comments.compact.unshift(0)]
    end

    def time_values(y_max, play_time)
      values = super
      moves = [0]
      return [moves, values] if values.size <= 1

      i = 2
      values[1, values.size-1].each do |v|
        moves << i
        i += 2
      end
      return [moves, values]
    end
  end # White

  
  def create_players
    black = Black.new("+")
    white = White.new("-")
    black.theOther = white
    white.theOther = black
    return black,white
  end
  module_function :create_players
end # module EvalGraph


def plot(csa_file, title, black, white, a_play_time)
  width = [black.comments.size, white.comments.size].max * 2 + 1
  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
      plot.terminal "svg" # or png
      plot.output   to_svg_file(csa_file)
      
      plot.title  title
      plot.size   "ratio #{1/1.618}"
      plot.xlabel "Moves"
      plot.ylabel "Evaluation Value"
      plot.xrange "[0:#{width}]"
      plot.yrange "[-3000:3000]"
      plot.xtics  "20"
      plot.mxtics "2"
      plot.ytics  %Q!("2000" 2000, "-2000" -2000)!
      plot.xzeroaxis "lt -1"
      plot.grid
      plot.size   "0.9,0.9"
      plot.key "left"
     
      plot.style "line 1 linewidth 5 linetype 0 linecolor rgbcolor \"red\"" 
      plot.style "line 2 linewidth 4 linetype 0 linecolor rgbcolor \"dark-green\"" 

      plot.data << Gnuplot::DataSet.new( black.eval_values ) do |ds|
        ds.with  = "lines ls 1"
        ds.title = black.name
      end
      
      plot.data << Gnuplot::DataSet.new( white.eval_values ) do |ds|
        ds.with  = "lines ls 2"
        ds.title = white.name
      end

      if a_play_time > 0
        plot.style "line 5 linewidth 1 linetype 0 linecolor rgbcolor \"red\"" 
        plot.style "line 6 linewidth 1 linetype 0 linecolor rgbcolor \"green\"" 
        plot.style "fill solid 0.25 noborder"

        plot.data << Gnuplot::DataSet.new( black.time_values(3000, a_play_time) ) do |ds|
          ds.with  = "boxes notitle ls 5"
        end
        
        plot.data << Gnuplot::DataSet.new( white.time_values(-3000, a_play_time) ) do |ds|
          ds.with  = "boxes notitle ls 6"
        end
      end # if

    end
  end  
end


# Read kifu, a record of moves, to generate a graph file. 
# lines are contents of the kifu.
# file is a file name of a genrating image file.
# original_file_name is a file name of the csa file.
#
def read(lines, file_name, original_file_name=nil)
  lines.map! {|l| l.strip}
  original_file_name ||=  file_name 
  
  black,white = EvalGraph.create_players
  while l = lines.shift do
    black << l
    white << l
  end
  
  title = "#{file_name}" 
  a_play_time = play_time(original_file_name)
  plot(file_name, title, black, white, a_play_time)
end


if $0 == __FILE__
  def usage
    puts "Usage: #{$0} [--update] <csa_files>..."
    puts "Options:"
    puts "  --update        Update .svg files if exist."
    exit 1
  end

  usage if ARGV.empty?

  parser = GetoptLong.new
  parser.set_options(['--update', GetoptLong::NO_ARGUMENT])
  begin
    parser.each_option do |name, arg|
      eval "$OPT_#{name.sub(/^--/, '').gsub(/-/, '_').upcase} = '#{arg}'"
    end
  rescue
    usage
  end
  
  while file = ARGV.shift
    next if !$OPT_UPDATE && File.exists?(to_svg_file(file))
    read(Pathname.new(file).readlines, file)
    str = reformat_svg(Pathname.new(to_svg_file(file)).read)
    open(to_svg_file(file),"w+") {|f| f << str}
  end
end
