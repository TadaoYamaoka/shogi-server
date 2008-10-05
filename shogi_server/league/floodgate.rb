module ShogiServer

class League
  class Floodgate
    class << self
      def game_name?(str)
        return /^floodgate-\d+-\d+$/.match(str) ? true : false
      end
    end

    attr_reader :next_time, :league

    def initialize(league, next_time=nil)
      @league = league
      @next_time = next_time
      charge
    end

    def charge
      now = Time.now
      unless $DEBUG
        # each 30 minutes
        if now.min < 30
          @next_time = Time.mktime(now.year, now.month, now.day, now.hour, 30)
        else
          @next_time = Time.mktime(now.year, now.month, now.day, now.hour) + 3600
        end
      else
        # for test, each 30 seconds
        if now.sec < 30
          @next_time = Time.mktime(now.year, now.month, now.day, now.hour, now.min, 30)
        else
          @next_time = Time.mktime(now.year, now.month, now.day, now.hour, now.min) + 60
        end
      end
    end

    def match_game
      players = @league.find_all_players do |pl|
        pl.status == "game_waiting" &&
        Floodgate.game_name?(pl.game_name) &&
        pl.sente == nil
      end
      Pairing.default_pairing.match(players)
    end
  end # class Floodgate

end # class League
end # module ShogiServer
