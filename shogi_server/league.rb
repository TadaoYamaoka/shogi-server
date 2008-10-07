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

require 'shogi_server/league/persistent'

module ShogiServer # for a namespace

######################################################
# League
#
class League

  def initialize(dir=File.dirname(__FILE__))
    @mutex = Monitor.new # guard @players
    @games = Hash::new
    @players = Hash::new
    @event = nil
    @dir = dir
  end
  attr_accessor :players, :games, :event, :dir

  # this should be called just after instanciating a League object.
  def setup_players_database
    filename = File.join(@dir, "players.yaml")
    @persistent = Persistent.new(filename)
  end

  def add(player)
    @persistent.load_player(player)
    @mutex.synchronize do
      @players[player.name] = player
    end
  end
  
  def delete(player)
    @mutex.synchronize do
      @players.delete(player.name)
    end
  end

  def reload
    @mutex.synchronize do
      @players.each do |name, player| 
        @persistent.load_player(player)
      end
    end
  end

  def find_all_players
    found = nil
    @mutex.synchronize do
      found = @players.find_all do |name, player|
        yield player
      end
    end
    return found.map {|a| a.last}
  end
  
  def find(player_name)
    found = nil
    @mutex.synchronize do
      found = @players[player_name]
    end
    return found
  end

  def get_player(status, game_name, sente, searcher)
    found = nil
    @mutex.synchronize do
      found = @players.find do |name, player|
        (player.status == status) &&
        (player.game_name == game_name) &&
        ( (sente == nil) || 
          (player.sente == nil) || 
          (player.sente == sente) ) &&
        (player.name != searcher.name)
      end
    end
    return found ? found.last : nil
  end
  
  def rated_players
    return @persistent.get_players
  end
end # class League

end # ShogiServer

