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

require 'shogi_server/util'

module ShogiServer

  class Pairing

    class << self
      def default_factory
        return swiss_pairing
      end

      def sort_by_rate_with_randomness
        return [LogPlayers.new,
                ExcludeSacrificeGps500.new,
                MakeEven.new,
                SortByRateWithRandomness.new(1200, 2400),
                StartGameWithoutHumans.new]
      end

      def random_pairing
        return [LogPlayers.new,
                ExcludeSacrificeGps500.new,
                MakeEven.new,
                Randomize.new,
                StartGameWithoutHumans.new]
      end

      def swiss_pairing
        return [LogPlayers.new,
                ExcludeSacrificeGps500.new,
                MakeEven.new,
                Swiss.new,
                StartGameWithoutHumans.new]
      end

      def match(players)
        logics = default_factory
        logics.inject(players) do |result, item|
          item.match(result)
          result
        end
      end
    end # class << self


    def match(players)
      # to be implemented
      log_message("Floodgate: %s" % [self.class.to_s])
    end

    def include_newbie?(players)
      return players.find{|a| a.rate == 0} == nil ? false : true
    end

    def less_than_one?(players)
      if players.size < 1
        log_warning("Floodgate: There should be at least one player.")
        return true
      else
        return false
      end
    end

    def log_players(players)
      str_array = players.map do |one|
        if block_given?
          yield one
        else
          one.name
        end
      end
      if str_array.empty?
        log_message("Floodgate: [Players] Nobody found.")
      else
        log_message("Floodgate: [Players] %s." % [str_array.join(", ")])
      end
    end
  end # Pairing


  class LogPlayers < Pairing
    def match(players)
      super
      log_players(players)
    end
  end

  class AbstractStartGame < Pairing
    def start_game(p1, p2)
      log_message("Floodgate: Starting a game: BLACK %s vs WHITE %s" % [p1.name, p2.name])
      p1.sente = true
      p2.sente = false
      board = Board.new
      board.initial
      Game.new(p1.game_name, p1, p2, board)
    end

    def start_game_shuffle(pair)
      pair.shuffle!
      start_game(pair.first, pair.last)
    end
  end

  class StartGame < AbstractStartGame
    def match(players)
      super
      if players.size < 2
        log_warning("Floodgate: There should be more than one player (%d)." % [players.size])
        return
      end
      if players.size.odd?
        log_warning("Floodgate: There are odd players (%d). %s will not be matched." % 
                    [players.size, players.last.name])
      end

      log_players(players)
      while (players.size >= 2) do
        pair = players.shift(2)
        start_game_shuffle(pair)
      end
    end
  end

  # This tries to avoid a human-human match
  #
  class StartGameWithoutHumans < AbstractStartGame
    def match(players)
      super
      log_players(players)
      if players.size < 2
        log_warning("Floodgate: There should be more than one player (%d)." % [players.size])
        return
      elsif players.size == 2
        start_game_shuffle(players)
        return
      end

      loop do 
        humans = get_human_indexes(players)
        log_message("Floodgate: There are (still) %d humans." % [humans.size])
        break if humans.size < 2

        pairing_possible = false
        for i in 0..(humans.size-2)  # -2
          next if humans[i].odd?
          if humans[i]+1 == humans[i+1]
            pairing_possible = humans[i]
            break
          end
        end
        unless pairing_possible
          log_message("Floodgate: No possible human-human match found")
          break
        end

        current_index = pairing_possible
        j = [0, current_index - 2].max
        while j < players.size
          break if players[j].is_computer?
          j += 1
        end

        pairing_indexes = []
        if j == players.size 
          # no computer player found
          pairing_indexes << current_index << current_index+1
        else
          # a comupter player found
          pairing_indexes << current_index << j
        end

        pair = []
        pair << players.delete_at(pairing_indexes.max)
        pair << players.delete_at(pairing_indexes.min)
        start_game_shuffle(pair)
      end # loop

      while (players.size >= 2) do
        pair = players.shift(2)
        start_game_shuffle(pair)
      end
    end

    private

    def get_human_indexes(players)
      ret = []
      for i in 0..(players.size-1)
        ret << i if players[i].is_human?
      end
      return ret
    end
  end

  class Randomize < Pairing
    def match(players)
      super
      log_message("Floodgate: Randomize... before")
      log_players(players)
      players.shuffle!
      log_message("Floodgate: Randomized after")
      log_players(players)
    end
  end # RadomPairing

  class SortByRate < Pairing
    def match(players)
      super
      log_message("Floodgate: Ordered by rate")
      players.sort! {|a,b| a.rate <=> b.rate} # decendent order
      log_players(players)
    end
  end

  class SortByRateWithRandomness < Pairing
    def initialize(rand1, rand2)
      super()
      @rand1, @rand2 = rand1, rand2
    end

    def match(players, desc=false)
      super(players)
      cur_rate = Hash.new
      players.each{|a| cur_rate[a] = a.rate ? a.rate + rand(@rand1) : rand(@rand2)}
      players.sort!{|a,b| cur_rate[a] <=> cur_rate[b]}
      players.reverse! if desc
      log_players(players) do |one|
        "%s %d (+ randomness %d)" % [one.name, one.rate, cur_rate[one] - one.rate]
      end
    end
  end

  class Swiss < Pairing
    def match(players)
      super
      if players.size < 3
        log_message("Floodgate: players are small enough to skip Swiss pairing: %d" % [players.size])
        return
      end

      path = ShogiServer::League::Floodgate.history_file_path(players.first.game_name)
      history = ShogiServer::League::Floodgate::History.factory(path)

      winners = []
      if history
        winners = players.find_all {|pl| history.last_win?(pl.player_id)}
      end
      rest = players - winners

      log_message("Floodgate: Ordering %d winners..." % [winners.size])
      sbrwr_winners = SortByRateWithRandomness.new(800, 2500)
      sbrwr_winners.match(winners, true)

      log_message("Floodgate: Ordering the rest (%d)..." % [rest.size])
      sbrwr_losers = SortByRateWithRandomness.new(200, 400)
      sbrwr_losers.match(rest, true)

      players.clear
      [winners, rest].each do |group|
        group.each {|pl| players << pl}
      end
    end
  end

  class DeletePlayerAtRandom < Pairing
    def match(players)
      super
      return if less_than_one?(players)
      one = players.choice
      log_message("Floodgate: Deleted %s at random" % [one.name])
      players.delete(one)
      log_players(players)
    end
  end

  class DeletePlayerAtRandomExcept < Pairing
    def initialize(except)
      super()
      @except = except
    end

    def match(players)
      super
      log_message("Floodgate: Deleting a player at rondom except %s" % [@except.name])
      players.delete(@except)
      DeletePlayerAtRandom.new.match(players)
      players.push(@except)
    end
  end
  
  class DeleteMostPlayingPlayer < Pairing
    def match(players)
      super
      one = players.max_by {|a| a.win + a.loss}
      log_message("Floodgate: Deleted the most playing player: %s (%d)" % [one.name, one.win + one.loss])
      players.delete(one)
      log_players(players)
    end
  end

  class DeleteLeastRatePlayer < Pairing
    def match(players)
      super
      one = players.min_by {|a| a.rate}
      log_message("Floodgate: Deleted the least rate player %s (%d)" % [one.name, one.rate])
      players.delete(one)
      log_players(players)
    end
  end

  class ExcludeSacrifice < Pairing
    attr_reader :sacrifice

    # @sacrifice a player id to be eliminated
    def initialize(sacrifice)
      super()
      @sacrifice = sacrifice
    end

    def match(players)
      super
      if @sacrifice && 
         players.size.odd? && 
         players.find{|a| a.player_id == @sacrifice}
         log_message("Floodgate: Deleting the sacrifice %s" % [@sacrifice])
         players.delete_if{|a| a.player_id == @sacrifice}
         log_players(players)
      end
    end
  end # class ExcludeSacrifice

  class ExcludeSacrificeGps500 < ExcludeSacrifice
    def initialize
      super("gps500+e293220e3f8a3e59f79f6b0efffaa931")
    end
  end

  class MakeEven < Pairing
    def match(players)
      super
      return if players.size.even?
      log_message("Floodgate: There are odd players (%d). Deleting one of them..." % 
                  [players.size])
      DeletePlayerAtRandom.new.match(players)
    end
  end

end # ShogiServer
