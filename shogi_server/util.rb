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

module ShogiServer

  # Generate a random number such as i<=n<max
  def random(i, max)
    raise if i >= max
    return rand(max-i)+i
  end
  module_function :random

  def shuffle(array)
    return if array.size < 2
    for i in 0...(array.size-1)
      r = random(i, array.size)
      a = array[i]
      array[i] = array[r]
      array[r] = a
    end
  end
  module_function :shuffle

end
