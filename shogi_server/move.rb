## $Id$

## Copyright (C) 2004 NABEYA Kenichi (aka nanami@2ch)
## Copyright (C) 2007-2012 Daigo Moriwaki (daigo at debian dot org)
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

class Move
  def initialize(x0, y0, x1, y1, name, sente)
    @x0 = x0
    @y0 = y0
    @x1 = x1
    @y1 = y1
    @name = name
    @sente = sente
    @promotion = false
    @captured_piece = nil
    @captured_piece_promoted = false
  end
  attr_reader :x0, :y0, :x1, :y1, :name, :sente, 
              :captured_piece, :captured_piece_promoted
  attr_accessor :promotion

  def set_captured_piece(piece)
    @captured_piece = piece
    @captured_piece_promoted = piece.promoted
  end

  def is_drop?
    return (@x0 == 0 || @y0 == 0)
  end
end

end # namespace
