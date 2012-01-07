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

require 'shogi_server/board'

module ShogiServer # for a namespace

# Handicapped game eliminating KY.
#
class HCKYBoard < Board
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
    #PieceKY::new(self, 9, 9, true)
    PieceKA::new(self, 8, 8, true)
    PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating KA.
#
class HCKABoard < Board
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
    #PieceKA::new(self, 8, 8, true)
    PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI.
#
class HCHIBoard < Board
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
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI and KY.
#
class HCHIKYBoard < Board
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
    #PieceKY::new(self, 9, 9, true)
    PieceKA::new(self, 8, 8, true)
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI and KA.
#
class HC2PBoard < Board
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
    #PieceKA::new(self, 8, 8, true)
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI, KA and two KYs.
#
class HC4PBoard < Board
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

    #PieceKY::new(self, 1, 9, true)
    PieceKE::new(self, 2, 9, true)
    PieceGI::new(self, 3, 9, true)
    PieceKI::new(self, 4, 9, true)
    PieceOU::new(self, 5, 9, true)
    PieceKI::new(self, 6, 9, true)
    PieceGI::new(self, 7, 9, true)
    PieceKE::new(self, 8, 9, true)
    #PieceKY::new(self, 9, 9, true)
    #PieceKA::new(self, 8, 8, true)
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI, KA, two KYs and two KE.
#
class HC6PBoard < Board
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

    #PieceKY::new(self, 1, 9, true)
    #PieceKE::new(self, 2, 9, true)
    PieceGI::new(self, 3, 9, true)
    PieceKI::new(self, 4, 9, true)
    PieceOU::new(self, 5, 9, true)
    PieceKI::new(self, 6, 9, true)
    PieceGI::new(self, 7, 9, true)
    #PieceKE::new(self, 8, 9, true)
    #PieceKY::new(self, 9, 9, true)
    #PieceKA::new(self, 8, 8, true)
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI, KA, two KYs, two KE and two GIs
#
class HC8PBoard < Board
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

    #PieceKY::new(self, 1, 9, true)
    #PieceKE::new(self, 2, 9, true)
    #PieceGI::new(self, 3, 9, true)
    PieceKI::new(self, 4, 9, true)
    PieceOU::new(self, 5, 9, true)
    PieceKI::new(self, 6, 9, true)
    #PieceGI::new(self, 7, 9, true)
    #PieceKE::new(self, 8, 9, true)
    #PieceKY::new(self, 9, 9, true)
    #PieceKA::new(self, 8, 8, true)
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

# Handicapped game eliminating HI, KA, two KYs, two KE, two GIs and two KIs.
#
class HC10PBoard < Board
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

    #PieceKY::new(self, 1, 9, true)
    #PieceKE::new(self, 2, 9, true)
    #PieceGI::new(self, 3, 9, true)
    #PieceKI::new(self, 4, 9, true)
    PieceOU::new(self, 5, 9, true)
    #PieceKI::new(self, 6, 9, true)
    #PieceGI::new(self, 7, 9, true)
    #PieceKE::new(self, 8, 9, true)
    #PieceKY::new(self, 9, 9, true)
    #PieceKA::new(self, 8, 8, true)
    #PieceHI::new(self, 2, 8, true)
    (1..9).each do |i|
      PieceFU::new(self, i, 7, true)
    end
    @teban = true
  end
end

end # ShogiServer

