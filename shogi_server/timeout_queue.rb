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

#   queue = Queue.new
#   timeout(5) do
#     queue.deq
#   end
#
# is not good since not all of stdlib is safe with respect to 
# asynchronous exceptions.
# This class is a safe implementation.
# See: http://www.ruby-forum.com/topic/107864
#

require 'monitor'

module ShogiServer

class TimeoutQueue
  def initialize(timeout=20)
    @timeout = timeout # sec
    @queue = []
    @mon  = Monitor.new
    @cond = @mon.new_cond
  end

  def enq(msg)
    @mon.synchronize do
      @queue.push(msg)
      @cond.broadcast
    end
  end

  #
  # @return :timeout if it timed out
  #
  def deq
    timeout_flg = false
    ret = :timeout
    @mon.synchronize do
      if @queue.empty?
        unless @cond.wait(@timeout)
          #timeout
          timeout_flg = true
        end
      end
      if !timeout_flg && !@queue.empty?
        ret = @queue.shift
      end
    end # synchronize
    return ret
  end

  def empty?
    ret = true
    @mon.synchronize do
      ret = @queue.empty?
    end
    return ret
  end

  def get_messages
    ret = nil
    @mon.synchronize do
      ret = @queue.dup
    end
    return ret
  end

end

end
