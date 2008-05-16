#!/usr/bin/env ruby
#    This generates graphs of evaluation values from comments in CSA files.
#    Ruby libraries that are required: 
#      - RubyGems: http://rubyforge.org/projects/rubygems/
#      - rgplot:   http://rubyforge.org/projects/rgplot/
#    OS librariles that is required:
#      - Gnuplot:  http://www.gnuplot.info/
#                  On Debian, $ sudo apt-get install gnuplot
#    
#    Copyright (C) 2006  Daigo Moriwaki <daigo@debian.org>
#
#    Version: $Id$
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

require 'pathname'
require 'getoptlong'
require 'rubygems'
require 'gnuplot'

def to_svg_file(csa_file)
  "#{csa_file}.svg"
end

def reformat_svg(str)
  str.gsub(%r!<svg.*?>!m, <<-END) 
	         <svg viewBox="0 0 800 600" 
					      xmlns="http://www.w3.org/2000/svg" 
								xmlns:xlink="http://www.w3.org/1999/xlink">
	         END
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
    
    def initialize(type)
			@comments = []
      @type = type
      @regexp_move = Regexp.new("^\\#{@type}\\d{4}\\w{2}")
      @regexp_name = Regexp.new("^N\\#{@type}(.*)")
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
      when /^'\*\*(.*)/
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

  end

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
  end

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
  end

  
  def create_players
    black = Black.new("+")
    white = White.new("-")
    black.theOther = white
    white.theOther = black
    return black,white
  end
  module_function :create_players
end


def plot(csa_file, title, black, white)
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
     
      plot.data << Gnuplot::DataSet.new( black.eval_values ) do |ds|
        ds.with  = "lines"
        ds.title = black.name
      end
      
      plot.data << Gnuplot::DataSet.new( white.eval_values ) do |ds|
        ds.with  = "lines"
        ds.title = white.name
      end
      
    end
  end  
end



def read(lines, file_name)
  lines.map! {|l| l.strip}
  
  black,white = EvalGraph.create_players
  while l = lines.shift do
    black << l
    white << l
  end
  
  title = "#{file_name}" 
  plot(file_name, title, black, white)
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
