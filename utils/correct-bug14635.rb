#!/usr/bin/ruby
# == Synopsis
#
# This program corrects illegal lines introduced by the #14635 bug.
#
# Author::    Daigo Moriwaki <daigo at debian dot org>
# Copyright:: Copyright (C) 2008  Daigo Moriwaki <daigo at debian dot org>
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
#
# == Usage
#
# correct-bug14635.rb [OPTIONS] DIR ...
# 
# --dry-run:
#   do not modify files, but show what will happen
#

require 'fileutils'
require 'getoptlong'
require 'nkf'
require 'pathname'

$KCODE="e"

class CheckCsaFile
  def initialize(file_path)
    @file = file_path
    @lines = []
  end

  def check
    puts @file if $DEBUG
    ret = false

    data = NKF.nkf("-e", @file.read)
    data.each_line do |line|
      case line.strip
      when ""
        puts "Found an empty line"
        ret = true
      when  /%%TORYO/
        puts "Found %%TORYO"
        @lines << line.gsub(/%%TORYO/, "%TORYO")
        ret = true
      when  /%%KACHI/
        puts "Found %%KACHI"
        @lines << line.gsub(/%%KACHI/, "%KACHI")
        ret = true
      else
        @lines << line
      end
    end

    return ret
  end

  def execute
    backup_name = @file.to_s + ".back"
    FileUtils.cp @file, backup_name
    @file.open("w") {|f| f.write @lines.join}
  end
end


if $0 == __FILE__
  def usage
    puts "Usage: #{$0} [OPTIONS] dir [...]"
    puts "Options:"
    puts "  --dry-run   do not modify files, but show what to do"
    exit 1
  end

  usage if ARGV.empty?

  parser = GetoptLong.new(
             ['--dry-run', GetoptLong::NO_ARGUMENT]
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
      path = Pathname.new(file)
      csa = CheckCsaFile.new(path)
      if csa.check
        puts path
        next if $OPT_DRY_RUN

        csa.execute
      end
    end
  end # while
end
