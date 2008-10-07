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

module ShogiServer

class League

  #
  # This manages those players who have their player_id.
  # Since mk_rate mainly updates the yaml file, basically,
  # this only reads data. But this writes some properties.
  # TODO Such data should be facoted out to another file
  #
  class Persistent
    def initialize(filename)
      @db = YAML::Store.new(filename)
      @db.transaction do |pstore|
        @db['players'] ||= Hash.new
      end
    end

    #
    # trancaction=true means read only
    #
    def each_group(transaction=false)
      @db.transaction(transaction) do
        groups = @db["players"] || Hash.new
        groups.each do |group, players|
          yield group,players
        end
      end
    end

    def load_player(player)
      return unless player.player_id

      hash = nil
      each_group(true) do |group, players|
        hash = players[player.player_id]
        break if hash
      end
      return unless hash

      # a current user
      player.name          = hash['name']
      player.rate          = hash['rate'] || 0
      player.modified_at   = hash['last_modified']
      player.rating_group  = hash['rating_group']
      player.win           = hash['win']  || 0
      player.loss          = hash['loss'] || 0
    end

    def get_players
      players = []
      each_group(true) do |group, players_hash|
        players << players_hash.keys
      end
      return players.flatten.collect do |player_id|
        p = BasicPlayer.new
        p.player_id = player_id
        load_player(p)
        p
      end
    end
  end # class Persistent

end # class League
end # module ShogiServer
