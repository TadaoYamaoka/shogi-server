require 'shogi_server'
require 'shogi_server/league/floodgate'

module ShogiServer

  class SetupFloodgate
    # Constructor.
    # @param game_names an array of game name strings
    #
    def initialize(game_names)
      @game_names = game_names
      @thread = nil
    end

    # Return the most recent Floodgate instance
    #
    def next_league(leagues)
      floodgate = leagues.min {|a,b| a.next_time <=> b.next_time}
      return floodgate
    end

    def floodgate_reload_log(leagues)
      floodgate = next_league(leagues)
      diff = floodgate.next_time - Time.now
      log_message("Floodgate reloaded. The next match will start at %s in %d seconds" % 
                  [floodgate.next_time, diff])
    end

    def mk_leagues
      leagues = @game_names.collect do |game_name|
        ShogiServer::League::Floodgate.new($league, 
                                           {:game_name => game_name})
      end
      leagues.delete_if do |floodgate|
        ret = false
        unless floodgate.next_time 
          log_error("Unsupported game name: %s" % floodgate.game_name)
          ret = true
        end
        ret
      end
      if leagues.empty?
        log_error("No valid Floodgate game names found")
        return [] # will exit the thread
      end
      floodgate_reload_log(leagues)
      return leagues
    end

    def wait_next_floodgate(floodgate)
      diff = floodgate.next_time - Time.now
      if diff > 0
        floodgate_reload_log(leagues) if $DEBUG
        sleep(diff/2)
        return true
      end
      return false
    end

    def reload_shogi_server
      $mutex.synchronize do
        log_message("Reloading source...")
        ShogiServer.reload
      end
    end

    def start_games(floodgate)
      log_message("Starting Floodgate games...: %s" % [floodgate.game_name])
      $league.reload
      floodgate.match_game
    end

    # Regenerate floodgate instances from next_array for the next matches.
    # @param next_array array of [game_name, next_time]
    #
    def regenerate_leagues(next_array)
      leagues = next_array.collect do |game_name, next_time|
        floodgate = ShogiServer::League::Floodgate.new($league, 
                                                       {:game_name => game_name,
                                                        :next_time => next_time})
      end
      floodgate_reload_log(leagues)
      return leagues
    end

    def start
      return nil if @game_names.nil? || @game_names.empty?

      log_message("Set up floodgate games: %s" % [@game_names.join(",")])
      @thread = Thread.start(@game_names) do |game_names|
        Thread.pass
        leagues = mk_leagues
        if leagues.nil? || leagues.empty?
          return # exit from this thread
        end

        while (true)
          begin
            floodgate = next_league(leagues)
            next if wait_next_floodgate(floodgate)

            next_array = leagues.collect do |floodgate|
              if (floodgate.next_time - Time.now) > 0
                [floodgate.game_name, floodgate.next_time]
              else
                start_games(floodgate)
                floodgate.charge # updates next_time
                [floodgate.game_name, floodgate.next_time] 
              end
            end

            reload_shogi_server

            # Regenerate floodgate instances after ShogiServer.realod
            leagues = regenerate_leagues(next_array)
          rescue Exception => ex 
            # ignore errors
            log_error("[in Floodgate's thread] #{ex} #{ex.backtrace}")
          end
        end # infinite loop

        return @thread
      end # Thread

    end # def start

    def kill
      @thread.kill if @thread
    end

  end # class SetupFloodgate

end # module ShogiServer
