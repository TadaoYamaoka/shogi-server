require 'shogi_server/util'
require 'date'
require 'thread'
require 'ostruct'
require 'pathname'

module ShogiServer

class League
  class Floodgate
    class << self
      # ex. "floodgate-900-0"
      #
      def game_name?(str)
        return /^floodgate\-\d+\-\d+$/.match(str) ? true : false
      end

      def history_file_path(gamename)
        return nil unless game_name?(gamename)
        filename = "floodgate_history_%s.yaml" % [gamename.gsub("floodgate-", "").gsub("-","_")]
        file = File.join($topdir, filename)
        return Pathname.new(file)
      end
    end # class method

    # @next_time is updated  if and only if charge() was called
    #
    attr_reader :next_time
    attr_reader :league, :game_name

    def initialize(league, hash={})
      @league = league
      @next_time = hash[:next_time] || nil
      @game_name = hash[:game_name] || "floodgate-900-0"
      charge if @next_time.nil?
    end

    def game_name?(str)
      return Regexp.new(@game_name).match(str) ? true : false
    end

    def charge
      ntg = NextTimeGenerator.factory(@game_name)
      if ntg
        @next_time = ntg.call(Time.now)
      else
        @next_time = nil
      end
    end

    def match_game
      players = @league.find_all_players do |pl|
        pl.status == "game_waiting" &&
        game_name?(pl.game_name) &&
        pl.sente == nil
      end
      Pairing.match(players)
    end
    
    #
    #
    class NextTimeGenerator
      class << self
        def factory(game_name)
          ret = nil
          conf_file_name = File.join($topdir, "#{game_name}.conf")

          if $DEBUG
            ret = NextTimeGenerator_Debug.new
          elsif File.exists?(conf_file_name) 
            lines = IO.readlines(conf_file_name)
            ret =  NextTimeGeneratorConfig.new(lines)
          elsif game_name == "floodgate-900-0"
            ret = NextTimeGenerator_Floodgate_900_0.new
          elsif game_name == "floodgate-3600-0"
            ret = NextTimeGenerator_Floodgate_3600_0.new
          end
          return ret
        end
      end
    end

    # Schedule the next time from configuration files.
    #
    # Line format: 
    #   # This is a comment line
    #   DoW Time
    #   ...
    # where
    #   DoW := "Sun" | "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" |
    #          "Sunday" | "Monday" | "Tuesday" | "Wednesday" | "Thursday" |
    #          "Friday" | "Saturday" 
    #   Time := HH:MM
    #
    # For example,
    #   Sat 13:00
    #   Sat 22:00
    #   Sun 13:00
    #
    class NextTimeGeneratorConfig
      
      # Constructor. 
      # Read configuration contents.
      #
      def initialize(lines)
        @lines = lines
      end

      def call(now=Time.now)
        if now.kind_of?(Time)
          now = ::ShogiServer::time2datetime(now)
        end
        candidates = []
        # now.cweek 1-53
        # now.cwday 1(Monday)-7
        @lines.each do |line|
          if %r!^\s*(\w+)\s+(\d{1,2}):(\d{1,2})! =~ line
            dow, hour, minute = $1, $2.to_i, $3.to_i
            dow_index = ::ShogiServer::parse_dow(dow)
            next if dow_index.nil?
            next unless (0..23).include?(hour)
            next unless (0..59).include?(minute)
            time = DateTime::commercial(now.cwyear, now.cweek, dow_index, hour, minute) rescue next
            time += 7 if time <= now 
            candidates << time
          end
        end
        candidates.map! {|dt| ::ShogiServer::datetime2time(dt)}
        return candidates.empty? ? nil : candidates.min
      end
    end

    # Schedule the next time for floodgate-900-0: each 30 minutes
    #
    class NextTimeGenerator_Floodgate_900_0
      def call(now)
        if now.min < 30
          return Time.mktime(now.year, now.month, now.day, now.hour, 30)
        else
          return Time.mktime(now.year, now.month, now.day, now.hour) + 3600
        end
      end
    end

    # Schedule the next time for floodgate-3600-0: each 2 hours (odd hour)
    #
    class NextTimeGenerator_Floodgate_3600_0
      def call(now)
        return Time.mktime(now.year, now.month, now.day, now.hour) + ((now.hour%2)+1)*3600
      end
    end

    # Schedule the next time for debug: each 30 seconds.
    #
    class NextTimeGenerator_Debug
      def call(now)
        if now.sec < 30
          return Time.mktime(now.year, now.month, now.day, now.hour, now.min, 30)
        else
          return Time.mktime(now.year, now.month, now.day, now.hour, now.min) + 60
        end
      end
    end

    #
    #
    class History
      @@mutex = Mutex.new

      class << self
        def factory(pathname)
          unless ShogiServer::is_writable_file?(pathname.to_s)
            log_error("Failed to write a history file: %s" % [pathname]) 
            return nil
          end
          history = History.new pathname
          history.load
          return history
        end
      end

      attr_reader :records

      # Initialize this instance.
      # @param file_path_name a Pathname object for this storage
      #
      def initialize(file_path_name)
        @records = []
        @max_records = 100
        @file = file_path_name
      end

      # Return a hash describing the game_result
      # :game_id: game id
      # :black:   Black's player id
      # :white:   White's player id
      # :winner:  Winner's player id or nil for the game without a winner
      # :loser:   Loser's player id or nil for the game without a loser
      #
      def make_record(game_result)
        hash = Hash.new
        hash[:game_id] = game_result.game.game_id
        hash[:black]   = game_result.black.player_id
        hash[:white]   = game_result.white.player_id
        case game_result
        when GameResultWin
          hash[:winner] = game_result.winner.player_id
          hash[:loser]  = game_result.loser.player_id
        else
          hash[:winner] = nil
          hash[:loser]  = nil
        end
        return hash
      end

      def load
        return unless @file.exist?

        @records = YAML.load_file(@file)
        unless @records && @records.instance_of?(Array)
          $logger.error "%s is not a valid yaml file. Instead, an empty array will be used and updated." % [@file]
          @records = []
        end
      end

      def save
        begin
          @file.open("w") do |f| 
            f << YAML.dump(@records)
          end
        rescue Errno::ENOSPC
          # ignore
        end
      end

      def update(game_result)
        record = make_record(game_result)
        @@mutex.synchronize do 
          load
          @records << record
          while @records.size > @max_records
            @records.shift
          end
          save
        end
      end
      
      def last_win?(player_id)
        rc = last_valid_game(player_id)
        return false unless rc
        return rc[:winner] == player_id
      end
      
      def last_lose?(player_id)
        rc = last_valid_game(player_id)
        return false unless rc
        return rc[:loser] == player_id
      end

      def last_opponent(player_id)
        rc = last_valid_game(player_id)
        return nil unless rc
        if rc[:black] == player_id
          return rc[:white]
        elsif rc[:white] == player_id
          return rc[:black]
        else
          return nil
        end
      end

      def last_valid_game(player_id)
        records = nil
        @@mutex.synchronize do
          records = @records.reverse
        end
        rc = records.find do |rc|
          rc[:winner] && 
          rc[:loser]  && 
          (rc[:black] == player_id || rc[:white] == player_id)
        end
        return rc
      end

      def win_games(player_id)
        records = nil
        @@mutex.synchronize do
          records = @records.reverse
        end
        rc = records.find_all do |rc|
          rc[:winner] == player_id && rc[:loser]
        end
        return rc
      end

      def loss_games(player_id)
        records = nil
        @@mutex.synchronize do
          records = @records.reverse
        end
        rc = records.find_all do |rc|
          rc[:winner] && rc[:loser] == player_id
        end
        return rc
      end
    end # class History


  end # class Floodgate


end # class League
end # module ShogiServer
