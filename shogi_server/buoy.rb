require 'shogi_server/config'
require 'shogi_server/game'
require 'yaml'
require 'yaml/store'

module ShogiServer

  class BuoyGame
    attr_reader :game_name
    attr_reader :moves
    attr_reader :owner
    attr_reader :count

    def initialize(game_name, moves, owner, count)
      raise "owner name is required" if owner && !owner.instance_of?(String)
      @game_name, @moves, @owner, @count = game_name, moves, owner, count
    end

    def decrement_count
      @count -= 1
    end

    def ==(rhs)
      return (@game_name == rhs.game_name && 
              @moves == rhs.moves &&
              @owner == rhs.owner &&
              @count == rhs.count)
    end
  end

  class NilBuoyGame < BuoyGame
    def initialize
      super(nil, nil, nil, 0)
    end
  end

  class Buoy

    # "buoy_hoge-900-0"
    #
    def Buoy.game_name?(str)
      return /^buoy_.*\-\d+\-\d+$/.match(str) ? true : false
    end

    def initialize(conf = {})
      @conf = $config || Config.new
      @conf.merge!(conf, true)
      filename = @conf[:buoy, :filename] || File.join(@conf[:topdir], "buoy.yaml")
      @db = YAML::Store.new(filename)
      @db.transaction do
      end
    end

    def is_new_game?(game_name)
      @db.transaction(true) do
        return !@db.root?(game_name)
      end
    end

    def add_game(buoy_game)
      @db.transaction do
        if @db.root?(buoy_game.game_name)
          # error
        else
          hash = {'moves' => buoy_game.moves,
                  'owner' => buoy_game.owner,
                  'count' => buoy_game.count}
          @db[buoy_game.game_name] = hash
        end
      end
    end

    def update_game(buoy_game)
      @db.transaction do
        if @db.root?(buoy_game.game_name)
          hash = {'moves' => buoy_game.moves,
                  'owner' => buoy_game.owner,
                  'count' => buoy_game.count}
          @db[buoy_game.game_name] = hash
        else
          # error
        end
      end
    end

    def delete_game(buoy_game)
      @db.transaction do
        @db.delete(buoy_game.game_name)
      end
    end

    def get_game(game_name)
      @db.transaction(true) do
        hash = @db[game_name]
        if hash
          moves = hash['moves']
          owner = hash['owner']
          count = hash['count'].to_i
          return BuoyGame.new(game_name, moves, owner, count)
        else
          return NilBuoyGame.new
        end
      end
    end

    def decrement_count(buoy_game)
      return if buoy_game.instance_of?(NilBuoyGame)

      buoy_game.decrement_count
      if buoy_game.count > 0
        update_game buoy_game
        log_message "Buoy #{buoy_game.game_name} remains #{buoy_game.count} slots."
      else                
        delete_game buoy_game
        log_message "Buoy #{buoy_game.game_name} finished."
      end
    end
  end

end # module ShogiServer
