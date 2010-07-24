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

require 'shogi_server/move'

module ShogiServer # for a namespace

class WrongMoves < ArgumentError; end

class Board
  
  # Split a moves line into an array of a move string.
  # If it fails to parse the moves, it raises WrongMoves.
  # @param moves a moves line. Ex. "+776FU-3334Fu"
  # @return an array of a move string. Ex. ["+7776FU", "-3334FU"]
  #
  def Board.split_moves(moves)
    ret = []

    rs = moves.gsub %r{[\+\-]\d{4}\w{2}} do |s|
           ret << s
           ""
         end
    raise WrongMoves, rs unless rs.empty?

    return ret
  end

  def initialize(move_count=0)
    @sente_hands = Array::new
    @gote_hands  = Array::new
    @history       = Hash::new(0)
    @sente_history = Hash::new(0)
    @gote_history  = Hash::new(0)
    @array = [[], [], [], [], [], [], [], [], [], []]
    @move_count = move_count
    @teban = nil # black => true, white => false
    @initial_moves = []
  end
  attr_accessor :array, :sente_hands, :gote_hands, :history, :sente_history, :gote_history, :teban
  attr_reader :move_count
  
  # Initial moves for a Buoy game. If it is an empty array, the game is
  # normal with the initial setting; otherwise, the game is started after the
  # moves.
  attr_reader :initial_moves

  # See if self equals rhs, including a logical board position (i.e.
  # not see object IDs) and sennichite stuff.
  #
  def ==(rhs)
    return @teban         == rhs.teban &&
           @move_count    == rhs.move_count &&
           to_s           == rhs.to_s &&
           @history       == rhs.history &&
           @sente_history == rhs.sente_history &&
           @gote_history  == rhs.gote_history &&
           @initial_moves == rhs.initial_moves
  end

  def deep_copy
    return Marshal.load(Marshal.dump(self))
  end

  def initial
    PieceKY::new(self, 1, 1, false)
    PieceKE::new(self, 2, 1, false)
    PieceGI::new(self, 3, 1, false)
    PieceKI::new(self, 4, 1, false)
    PieceOU::new(self, 5, 1, false)
    PieceKI::new(self, 6, 1, false)
    PieceGI::new(self, 7, 1, false)
    PieceKE::new(self, 8, 1, false)
    PieceKY::new(self, 9, 1, false)
    PieceKA::new(self, 2, 2, false)
    PieceHI::new(self, 8, 2, false)
    (1..9).each do |i|
      PieceFU::new(self, i, 3, false)
    end

    PieceKY::new(self, 1, 9, true)
    PieceKE::new(self, 2, 9, true)
    PieceGI::new(self, 3, 9, true)
    PieceKI::new(self, 4, 9, true)
    PieceOU::new(self, 5, 9, true)
    PieceKI::new(self, 6, 9, true)
    PieceGI::new(self, 7, 9, true)
    PieceKE::new(self, 8, 9, true)
    PieceKY::new(self, 9, 9, true)
    PieceKA::new(self, 8, 8, true)
    PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end

  # Set up a board with the strs.
  # Failing to parse the moves raises an StandardError.
  # @param strs a board text
  #
  def set_from_str(strs)
    strs.each_line do |str|
      case str
      when /^P\d/
        str.sub!(/^P(.)/, '')
        y = $1.to_i
        x = 9
        while (str.length > 2)
          str.sub!(/^(...?)/, '')
          one = $1
          if (one =~ /^([\+\-])(..)/)
            sg = $1
            name = $2
            if (sg == "+")
              sente = true
            else
              sente = false
            end
            if ((x < 1) || (9 < x) || (y < 1) || (9 < y))
              raise "bad position #{x} #{y}"
            end
            case (name)
            when "FU"
              PieceFU::new(self, x, y, sente)
            when "KY"
              PieceKY::new(self, x, y, sente)
            when "KE"
              PieceKE::new(self, x, y, sente)
            when "GI"
              PieceGI::new(self, x, y, sente)
            when "KI"
              PieceKI::new(self, x, y, sente)
            when "OU"
              PieceOU::new(self, x, y, sente)
            when "KA"
              PieceKA::new(self, x, y, sente)
            when "HI"
              PieceHI::new(self, x, y, sente)
            when "TO"
              PieceFU::new(self, x, y, sente, true)
            when "NY"
              PieceKY::new(self, x, y, sente, true)
            when "NK"
              PieceKE::new(self, x, y, sente, true)
            when "NG"
              PieceGI::new(self, x, y, sente, true)
            when "UM"
              PieceKA::new(self, x, y, sente, true)
            when "RY"
              PieceHI::new(self, x, y, sente, true)
            else
              raise "unkown piece #{name}"
            end
          end
          x = x - 1
        end
      when /^P([\+\-])/
        sg = $1
        if (sg == "+")
          sente = true
        else
          sente = false
        end
        str.sub!(/^../, '')
        while (str.length > 3)
          str.sub!(/^..(..)/, '')
          name = $1
          case (name)
          when "FU"
            PieceFU::new(self, 0, 0, sente)
          when "KY"
            PieceKY::new(self, 0, 0, sente)
          when "KE"
            PieceKE::new(self, 0, 0, sente)
          when "GI"
            PieceGI::new(self, 0, 0, sente)
          when "KI"
            PieceKI::new(self, 0, 0, sente)
          when "KA"
            PieceKA::new(self, 0, 0, sente)
          when "HI"
            PieceHI::new(self, 0, 0, sente)
          else
            raise "unkown piece #{name}"
          end
        end # while
      when /^\+$/
        @teban = true
      when /^\-$/
        @teban = false
      else
        raise "bad line: #{str}"
      end # case
    end # do
  end

  # Set up a board starting with a position after the moves.
  # Failing to parse the moves raises an ArgumentError.
  # @param moves an array of moves. ex. ["+7776FU", "-3334FU"]
  #
  def set_from_moves(moves)
    initial()
    return :normal if moves.empty?
    rt = nil
    moves.each do |move|
      rt = handle_one_move(move, @teban)
      raise ArgumentError, "bad moves: #{moves}" unless rt == :normal
    end
    @initial_moves = moves.dup
  end

  def have_piece?(hands, name)
    piece = hands.find { |i|
      i.name == name
    }
    return piece
  end

  # :illegal and :outori do not change this instance (self).
  #
  def move_to(move)
    x0, x1, y0, y1, name, sente = move.x0, move.x1, move.y0, move.y1, move.name, move.sente
    if (sente)
      hands = @sente_hands
    else
      hands = @gote_hands
    end

    if move.is_drop?
      piece = have_piece?(hands, name)
      return :illegal if (piece == nil || ! piece.move_to?(x1, y1, name))
      piece.move_to(x1, y1)
    else
      if (@array[x0][y0] == nil || !@array[x0][y0].move_to?(x1, y1, name))
        return :illegal
      end
      if (@array[x1][y1] && @array[x1][y1].name == "OU")
          return :outori
      end

      # Change the state of this instance (self)
      if (@array[x0][y0].name != name && !@array[x0][y0].promoted)
        # the piece is promoting
        @array[x0][y0].promoted = true
        move.promotion = true
      end
      if (@array[x1][y1]) # capture
        move.set_captured_piece(@array[x1][y1])
        @array[x1][y1].sente = @array[x0][y0].sente
        @array[x1][y1].move_to(0, 0)
        hands.sort! {|a, b| # TODO refactor. Move to Piece class
          a.name <=> b.name
        }
      end
      @array[x0][y0].move_to(x1, y1)
    end
    @move_count += 1
    @teban = @teban ? false : true
    return true
  end

  # Get back the previous move, which moved a name piece from [x0,y0] to 
  # [x1, y1] with or without promotion. If the move captured
  # a piece, it is captured_piece, which is now in hand. The captured_piece
  # was promoted or unpromoted.
  #
  def move_back(move)
    if (move.sente)
      hands = @sente_hands
    else
      hands = @gote_hands
    end

    piece = @array[move.x1][move.y1]
    if move.is_drop?
      piece.move_to(0, 0)
    else
      piece.move_to(move.x0, move.y0)
      piece.promoted = false if piece.promoted && move.promotion
      if move.captured_piece 
        move.captured_piece.move_to(move.x1, move.y1)
        move.captured_piece.sente = move.sente ? false : true
        move.captured_piece.promoted = true if move.captured_piece_promoted 
      end
    end
    
    @move_count -= 1
    @teban = @teban ? false : true
    return true
  end
  
  # def each_reserved_square

  def look_for_ou(sente)
    x = 1
    while (x <= 9)
      y = 1
      while (y <= 9)
        if (@array[x][y] &&
            (@array[x][y].name == "OU") &&
            (@array[x][y].sente == sente))
          return @array[x][y]
        end
        y = y + 1
      end
      x = x + 1
    end
    raise "can't find ou"
  end

  # See if sente is checked (i.e. loosing) or not.
  # Note that the method name "checkmated?" is wrong. Instead, it should be
  # "checked?" 
  #
  def checkmated?(sente)
    ou = look_for_ou(sente)
    x = 1
    while (x <= 9)
      y = 1
      while (y <= 9)
        if (@array[x][y] &&
            (@array[x][y].sente != sente))
          if (@array[x][y].movable_grids.include?([ou.x, ou.y]))
            return true
          end
        end
        y = y + 1
      end
      x = x + 1
    end
    return false
  end

  # See if sente's FU drop checkmates the opponent or not.
  #
  def uchifuzume?(sente)
    rival_ou = look_for_ou(! sente)   # rival's ou
    if (sente)                  # rival is gote
      if ((rival_ou.y != 9) &&
          (@array[rival_ou.x][rival_ou.y + 1]) &&
          (@array[rival_ou.x][rival_ou.y + 1].name == "FU") &&
          (@array[rival_ou.x][rival_ou.y + 1].sente == sente)) # uchifu true
        fu_x = rival_ou.x
        fu_y = rival_ou.y + 1
      else
        return false
      end
    else                        # gote
      if ((rival_ou.y != 1) &&
          (@array[rival_ou.x][rival_ou.y - 1]) &&
          (@array[rival_ou.x][rival_ou.y - 1].name == "FU") &&
          (@array[rival_ou.x][rival_ou.y - 1].sente == sente)) # uchifu true
        fu_x = rival_ou.x
        fu_y = rival_ou.y - 1
      else
        return false
      end
    end

    ## case: rival_ou is moving
    rival_ou.movable_grids.each do |(cand_x, cand_y)|
      tmp_board = deep_copy
      s = tmp_board.move_to(Move.new(rival_ou.x, rival_ou.y, cand_x, cand_y, "OU", ! sente))
      raise "internal error" if (s != true)
      if (! tmp_board.checkmated?(! sente)) # good move
        return false
      end
    end

    ## case: rival is capturing fu
    x = 1
    while (x <= 9)
      y = 1
      while (y <= 9)
        if (@array[x][y] &&
            (@array[x][y].sente != sente) &&
            @array[x][y].movable_grids.include?([fu_x, fu_y])) # capturable
          
          names = []
          if (@array[x][y].promoted)
            names << @array[x][y].promoted_name
          else
            names << @array[x][y].name
            if @array[x][y].promoted_name && 
               @array[x][y].move_to?(fu_x, fu_y, @array[x][y].promoted_name)
              names << @array[x][y].promoted_name 
            end
          end
          names.map! do |name|
            tmp_board = deep_copy
            s = tmp_board.move_to(Move.new(x, y, fu_x, fu_y, name, ! sente))
            if s == :illegal
              s # result
            else
              tmp_board.checkmated?(! sente) # result
            end
          end
          all_illegal = names.find {|a| a != :illegal}
          raise "internal error: legal move not found" if all_illegal == nil
          r = names.find {|a| a == false} # good move
          return false if r == false # found good move
        end
        y = y + 1
      end
      x = x + 1
    end
    return true
  end

  # @[sente|gote]_history has at least one item while the player is checking the other or 
  # the other escapes.
  def update_sennichite(player)
    str = to_s
    @history[str] += 1
    if checkmated?(!player)
      if (player)
        @sente_history["dummy"] = 1  # flag to see Sente player is checking Gote player
      else
        @gote_history["dummy"]  = 1  # flag to see Gote player is checking Sente player
      end
    else
      if (player)
        @sente_history.clear # no more continuous check
      else
        @gote_history.clear  # no more continuous check
      end
    end
    if @sente_history.size > 0  # possible for Sente's or Gote's turn
      @sente_history[str] += 1
    end
    if @gote_history.size > 0   # possible for Sente's or Gote's turn
      @gote_history[str] += 1
    end
  end

  # Deep-copy sennichite stuff, which will later be available to restore.
  #
  def dup_sennichite_stuff
    return [@history.dup, @sente_history.dup, @gote_history.dup]
  end

  # Restore sennihite stuff.
  #
  def restore_sennichite_stuff(history, sente_history, gote_history)
    @history, @sente_history, @gote_history = history, sente_history, gote_history
  end

  def oute_sennichite?(player)
    return nil unless sennichite?

    if player
      # sente's turn
      if (@sente_history[to_s] >= 4)   # sente is checking gote
        return :oute_sennichite_sente_lose
      elsif (@gote_history[to_s] >= 3) # sente is escaping
        return :oute_sennichite_gote_lose
      else
        return nil # Not oute_sennichite, but sennichite
      end
    else
      # gote's turn
      if (@gote_history[to_s] >= 4)     # gote is checking sente
        return :oute_sennichite_gote_lose
      elsif (@sente_history[to_s] >= 3) # gote is escaping
        return :oute_sennichite_sente_lose
      else
        return nil # Not oute_sennichite, but sennichite
      end
    end
  end

  def sennichite?
    if (@history[to_s] >= 4) # already 3 times
      return true
    end
    return false
  end

  def good_kachi?(sente)
    if (checkmated?(sente))
      puts "'NG: Checkmating." if $DEBUG
      return false 
    end
    
    ou = look_for_ou(sente)
    if (sente && (ou.y >= 4))
      puts "'NG: Black's OU does not enter yet." if $DEBUG
      return false     
    end  
    if (! sente && (ou.y <= 6))
      puts "'NG: White's OU does not enter yet." if $DEBUG
      return false 
    end
      
    number = 0
    point = 0

    if (sente)
      hands = @sente_hands
      r = [1, 2, 3]
    else
      hands = @gote_hands
      r = [7, 8, 9]
    end
    r.each do |y|
      x = 1
      while (x <= 9)
        if (@array[x][y] &&
            (@array[x][y].sente == sente) &&
            (@array[x][y].point > 0))
          point = point + @array[x][y].point
          number = number + 1
        end
        x = x + 1
      end
    end
    hands.each do |piece|
      point = point + piece.point
    end

    if (number < 10)
      puts "'NG: Piece#[%d] is too small." % [number] if $DEBUG
      return false     
    end  
    if (sente)
      if (point < 28)
        puts "'NG: Black's point#[%d] is too small." % [point] if $DEBUG
        return false 
      end  
    else
      if (point < 27)
        puts "'NG: White's point#[%d] is too small." % [point] if $DEBUG
        return false 
      end
    end

    puts "'Good: Piece#[%d], Point[%d]." % [number, point] if $DEBUG
    return true
  end

  # sente is nil only if tests in test_board run
  # @return
  #   - :normal
  #   - :toryo 
  #   - :kachi_win 
  #   - :kachi_lose 
  #   - :sennichite 
  #   - :oute_sennichite_sente_lose 
  #   - :oute_sennichite_gote_lose 
  #   - :illegal 
  #   - :uchifuzume 
  #   - :oute_kaihimore 
  #   - (:outori will not be returned)
  #
  def handle_one_move(str, sente=nil)
    if (str =~ /^([\+\-])(\d)(\d)(\d)(\d)([A-Z]{2})/)
      sg = $1
      x0 = $2.to_i
      y0 = $3.to_i
      x1 = $4.to_i
      y1 = $5.to_i
      name = $6
    elsif (str =~ /^%KACHI/)
      raise ArgumentError, "sente is null", caller if sente == nil
      if (good_kachi?(sente))
        return :kachi_win
      else
        return :kachi_lose
      end
    elsif (str =~ /^%TORYO/)
      return :toryo
    else
      return :illegal
    end
    
    if (((x0 == 0) || (y0 == 0)) && # source is not from hand
        ((x0 != 0) || (y0 != 0)))
      return :illegal
    elsif ((x1 == 0) || (y1 == 0)) # destination is out of board
      return :illegal
    end
    
    if (sg == "+")
      sente = true if sente == nil           # deprecated
      return :illegal unless sente == true   # black player's move must be black
      hands = @sente_hands
    else
      sente = false if sente == nil          # deprecated
      return :illegal unless sente == false  # white player's move must be white
      hands = @gote_hands
    end
    
    ## source check
    if ((x0 == 0) && (y0 == 0))
      return :illegal if (! have_piece?(hands, name))
    elsif (! @array[x0][y0])
      return :illegal           # no piece
    elsif (@array[x0][y0].sente != sente)
      return :illegal           # this is not mine
    elsif (@array[x0][y0].name != name)
      return :illegal if (@array[x0][y0].promoted_name != name) # can't promote
    end

    ## destination check
    if (@array[x1][y1] &&
        (@array[x1][y1].sente == sente)) # can't capture mine
      return :illegal
    elsif ((x0 == 0) && (y0 == 0) && @array[x1][y1])
      return :illegal           # can't put on existing piece
    end

    move = Move.new(x0, y0, x1, y1, name, sente)
    result = move_to(move)
    if (result == :illegal)
      # self is unchanged
      return :illegal 
    end
    if (checkmated?(sente))
      move_back(move)
      return :oute_kaihimore 
    end
    if ((x0 == 0) && (y0 == 0) && (name == "FU") && uchifuzume?(sente))
      move_back(move)
      return :uchifuzume
    end

    sennichite_stuff = dup_sennichite_stuff
    update_sennichite(sente)
    os_result = oute_sennichite?(sente)
    if os_result # :oute_sennichite_sente_lose or :oute_sennichite_gote_lose
      move_back(move)
      restore_sennichite_stuff(*sennichite_stuff)
      return os_result 
    end
    if sennichite?
      move_back(move)
      restore_sennichite_stuff(*sennichite_stuff)
      return :sennichite 
    end

    return :normal
  end

  def to_s
    a = Array::new
    y = 1
    while (y <= 9)
      a.push(sprintf("P%d", y))
      x = 9
      while (x >= 1)
        piece = @array[x][y]
        if (piece)
          s = piece.to_s
        else
          s = " * "
        end
        a.push(s)
        x = x - 1
      end
      a.push(sprintf("\n"))
      y = y + 1
    end
    if (! sente_hands.empty?)
      a.push("P+")
      sente_hands.each do |p|
        a.push("00" + p.name)
      end
      a.push("\n")
    end
    if (! gote_hands.empty?)
      a.push("P-")
      gote_hands.each do |p|
        a.push("00" + p.name)
      end
      a.push("\n")
    end
    a.push("%s\n" % [@teban ? "+" : "-"])
    return a.join
  end
end

end # ShogiServer
