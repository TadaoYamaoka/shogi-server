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
      player.last_game_win = hash['last_game_win'] || false
    end

    def save(player)
      return unless player.player_id

      each_group do |group, players|
        hash = players[player.player_id]
        if hash
          # write only this property. 
          # the others are updated by ./mk_rate
          hash['last_game_win'] = player.last_game_win
          break
        end
      end
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
