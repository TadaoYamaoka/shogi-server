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

class Board
  def initialize
    @sente_hands = Array::new
    @gote_hands  = Array::new
    @history       = Hash::new(0)
    @sente_history = Hash::new(0)
    @gote_history  = Hash::new(0)
    @array = [[], [], [], [], [], [], [], [], [], []]
    @move_count = 0
    @teban = nil # black => true, white => false
  end
  attr_accessor :array, :sente_hands, :gote_hands, :history, :sente_history, :gote_history, :teban
  attr_reader :move_count

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

  def have_piece?(hands, name)
    piece = hands.find { |i|
      i.name == name
    }
    return piece
  end

  def move_to(x0, y0, x1, y1, name, sente)
    if (sente)
      hands = @sente_hands
    else
      hands = @gote_hands
    end

    if ((x0 == 0) || (y0 == 0))
      piece = have_piece?(hands, name)
      return :illegal if (! piece.move_to?(x1, y1, name)) # TODO null check for the piece?
      piece.move_to(x1, y1)
    else
      return :illegal if (! @array[x0][y0].move_to?(x1, y1, name))  # TODO null check?
      if (@array[x0][y0].name != name) # promoted ?
        @array[x0][y0].promoted = true
      end
      if (@array[x1][y1]) # capture
        if (@array[x1][y1].name == "OU")
          return :outori        # return board update
        end
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

  # note checkmate, but check. sente is checked.
  def checkmated?(sente)        # sente is loosing
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
      tmp_board = Marshal.load(Marshal.dump(self))
      s = tmp_board.move_to(rival_ou.x, rival_ou.y, cand_x, cand_y, "OU", ! sente)
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
            tmp_board = Marshal.load(Marshal.dump(self))
            s = tmp_board.move_to(x, y, fu_x, fu_y, name, ! sente)
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

  def oute_sennichite?(player)
    if (@sente_history[to_s] >= 4)
      return :oute_sennichite_sente_lose
    elsif (@gote_history[to_s] >= 4)
      return :oute_sennichite_gote_lose
    else
      return nil
    end
  end

  def sennichite?(sente)
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

    tmp_board = Marshal.load(Marshal.dump(self))
    return :illegal if (tmp_board.move_to(x0, y0, x1, y1, name, sente) == :illegal)
    return :oute_kaihimore if (tmp_board.checkmated?(sente))
    tmp_board.update_sennichite(sente)
    os_result = tmp_board.oute_sennichite?(sente)
    return os_result if os_result # :oute_sennichite_sente_lose or :oute_sennichite_gote_lose
    return :sennichite if tmp_board.sennichite?(sente)

    if ((x0 == 0) && (y0 == 0) && (name == "FU") && tmp_board.uchifuzume?(sente))
      return :uchifuzume
    end

    move_to(x0, y0, x1, y1, name, sente)

    update_sennichite(sente)
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
