module ShogiServer

  class Pairing

    class << self
      def default_pairing
        return SwissPairing.new
        #return ExcludeSacrifice.new(SwissPairing.new)
        #return RandomPairing.new
        #return ExcludeSacrifice.new(RandomPairing.new)
      end
    end

    def match(players)
      if players.size < 2
        log_message("Floodgate[%s]: too few players [%d]" % 
                    [self.class, players.size])
      else
        log_message("Floodgate[%s]: found %d players. Pairing them..." % 
                    [self.class, players.size])
      end
    end

    def start_game(p1, p2)
      p1.sente = true
      p2.sente = false
      Game.new(p1.game_name, p1, p2)
    end

    def delete_player_at_random(players)
      return players.delete_at(rand(players.size))
    end

    def delete_player_at_random_except(players, a_player)
      candidates = players - [a_player]
      return delete_player_at_random(candidates)
    end
    
    def delete_most_playing_player(players)
      max_player = players.max {|a,b| a.win + a.loss <=> b.win + b.loss}
      return players.delete(max_player)
    end

    def delete_least_rate_player(players)
      min_player = players.min {|a,b| a.rate <=> b.rate}
      return players.delete(min_player)
    end

    def pairing_and_start_game(players)
      return if players.size < 2
      if players.size % 2 == 1
        log_warning("#Players should be even: %d" % [players.size])
        return
      end
      sorted = players.sort{ rand < 0.5 ? 1 : -1 }

      pairs = [[sorted.shift]]
      while !sorted.empty? do
        if pairs.last.size < 2
          pairs.last << sorted.shift
        else
          pairs << [sorted.shift]
        end 
      end
      pairs.each do |pair|
        start_game(pair.first, pair.last)
      end
    end
  end # Pairing

  class RandomPairing < Pairing
    def match(players)
      super
      return if players.size < 2

      if players.size % 2 == 1
        delete_most_playing_player(players)
      end
      pairing_and_start_game(players)
    end
  end # RadomPairing

  class SwissPairing < Pairing
    def match(players)
      super
      return if players.size < 2

      win_players = players.find_all {|a| a.last_game_win?}
      remains     = players - win_players
      if win_players.size >= 2
        if win_players.size % 2 == 1
          remains << delete_least_rate_player(win_players)
        end         
        pairing_and_start_game(win_players)
      else
        remains.concat(win_players)
      end
      return if remains.size < 2
      if remains.size % 2 == 1
        delete_most_playing_player(remains)
      end
      pairing_and_start_game(remains)
    end
  end # SwissPairing

  class ExcludeSacrifice
    attr_accessor :sacrifice

    def initialize(pairing)
      @pairing  = pairing
      @sacrifice = "gps500+e293220e3f8a3e59f79f6b0efffaa931"
    end

    def match(players)
      if @sacrifice && 
         players.size % 2 == 1 && 
         players.find{|a| a.id == @sacrifice}
        log_message("Floodgate: first, exclude %s" % [@sacrifice])
        players.delete_if{|a| a.id == @sacrifice}
      end
      @pairing.match(players)
    end

    # Delegate to @pairing
    def method_missing(message, *arg)
      @pairing.send(message, *arg)
    end
  end # class ExcludeSacrifice
end # ShogiServer
