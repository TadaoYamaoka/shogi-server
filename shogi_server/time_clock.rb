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

module ShogiServer # for a namespace

# Abstract class to caclulate thinking time.
#
class TimeClock

  def TimeClock.factory(least_time_per_move, game_name)
    time_map = Game.parse_time game_name

    if time_map[:stop_watch]
      @time_clock = StopWatchClock.new(least_time_per_move, time_map[:total_time], time_map[:byoyomi])
    else
      if least_time_per_move == 0
        @time_clock = ChessClockWithLeastZero.new(least_time_per_move,
                                                  time_map[:total_time],
                                                  time_map[:byoyomi],
                                                  time_map[:fischer])
      else
        @time_clock = ChessClock.new(least_time_per_move,
                                     time_map[:total_time],
                                     time_map[:byoyomi],
                                     time_map[:fischer])
      end
    end

    @time_clock
  end

  def initialize(least_time_per_move, total_time, byoyomi, fischer=0)
    @least_time_per_move = least_time_per_move
    @total_time = total_time
    @byoyomi    = byoyomi
    @fischer    = fischer
  end

  # Returns thinking time duration
  #
  def time_duration(mytime, start_time, end_time)
    # implement this
    return 9999999
  end

  # Returns what "Time_Unit:" in CSA protocol should provide.
  #
  def time_unit
    return "1sec"
  end

  # If thinking time runs out, returns true; false otherwise.
  #
  def timeout?(player, start_time, end_time)
    # implement this
    return true
  end

  # Updates a player's remaining time and returns thinking time.
  #
  def process_time(player, start_time, end_time)
    t = time_duration(player.mytime, start_time, end_time)

    player.mytime += @fischer
    player.mytime -= t
    if (player.mytime < 0)
      player.mytime = 0
    end

    return t
  end
end

# Calculates thinking time with chess clock.
#
class ChessClock < TimeClock
  def initialize(least_time_per_move, total_time, byoyomi, fischer=0)
    super
  end

  def time_duration(mytime, start_time, end_time)
    return [(end_time - start_time).floor, @least_time_per_move].max
  end

  def timeout?(player, start_time, end_time)
    t = time_duration(player.mytime, start_time, end_time)

    if ((player.mytime - t + @byoyomi + @fischer <= 0) &&
        ((@total_time > 0) || (@byoyomi > 0) || (@fischer > 0)))
      return true
    else
      return false
    end
  end

  def to_s
    return "ChessClock: LeastTimePerMove %d; TotalTime %d; Byoyomi %d; Fischer" %
      [@least_time_per_move, @total_time, @byoyomi, @fischer]
  end
end

# Calculates thinking time with chess clock, truncating decimal seconds for
# thinking time. This is a new rule that CSA introduced in November 2014.
#
# least_time_per_move should be 0.
# byoyomi should be more than 0.
#
class ChessClockWithLeastZero < ChessClock
  def initialize(least_time_per_move, total_time, byoyomi, fischer=0)
    if least_time_per_move != 0
      raise ArgumentError, "least_time_per_move #{least_time_per_move} should be 0."
    end
    super
  end

  def to_s
    return "ChessClockWithLeastZero: LeastTimePerMove %d; TotalTime %d; Byoyomi %d; Fischer %d" %
      [@least_time_per_move, @total_time, @byoyomi, @fischer]
  end
end

# StopWatchClock does not support Fischer time.
#
class StopWatchClock < TimeClock
  def initialize(least_time_per_move, total_time, byoyomi)
    super least_time_per_move, total_time, byoyomi, 0
  end

  def time_unit
    return "1min"
  end

  def time_duration(mytime, start_time, end_time)
    t = [(end_time - start_time).floor, @least_time_per_move].max
    return (t / @byoyomi) * @byoyomi
  end

  def timeout?(player, start_time, end_time)
    t = time_duration(player.mytime, start_time, end_time)

    if (player.mytime <= t)
      return true
    else
      return false
    end
  end

  def to_s
    return "StopWatchClock: LeastTimePerMove %d; TotalTime %d; Byoyomi %d" % [@least_time_per_move, @total_time, @byoyomi]
  end
end

end
