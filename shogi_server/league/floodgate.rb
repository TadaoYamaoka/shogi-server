module ShogiServer

class League
  class Floodgate
    class << self
      def game_name?(str)
        return /^floodgate-\d+-\d+$/.match(str) ? true : false
      end
    end

    def initialize(league)
      @league = league
      @next_time = nil
      charge
    end

    def run
      @thread = Thread.new do
        Thread.pass
        while (true)
          begin
            sleep(10)
            next if Time.now < @next_time
            @league.reload
            match_game
            charge
          rescue Exception => ex 
            # ignore errors
            log_error("[in Floodgate's thread] #{ex} #{ex.backtrace}")
          end
        end
      end
    end

    def shutdown
      @thread.kill if @thread
    end

    # private

    def charge
      now = Time.now
      # if now.min < 30
      #   @next_time = Time.mktime(now.year, now.month, now.day, now.hour, 30)
      # else
      #   @next_time = Time.mktime(now.year, now.month, now.day, now.hour) + 3600
      # end
      # for test
      if now.sec < 30
        @next_time = Time.mktime(now.year, now.month, now.day, now.hour, now.min, 30)
      else
        @next_time = Time.mktime(now.year, now.month, now.day, now.hour, now.min) + 60
      end
    end

    def match_game
      players = @league.find_all_players do |pl|
        pl.status == "game_waiting" &&
        Floodgate.game_name?(pl.game_name) &&
        pl.sente == nil
      end
      #log_warning("DEBUG: %s" % [File.join(File.dirname(__FILE__), "pairing.rb")])
      #load File.join(File.dirname(__FILE__), "pairing.rb")
      Pairing.default_pairing.match(players)
    end
  end # class Floodgate

end # class League
end # module ShogiServer
