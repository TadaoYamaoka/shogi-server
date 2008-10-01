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

require 'thread'
require 'monitor'

module ShogiServer

class TimeoutQueue
  def initialize
    @lock = Mutex.new
    @messages = []
    @readers  = []
  end

  def enq(msg)
    @lock.synchronize do
      unless @readers.empty?
        @readers.pop << msg
      else
        @messages.push msg
      end
    end
  end

  #
  # @param timeout
  # @return nil if timeout
  #
  def deq(timeout=5)
    timeout_thread = nil
    mon = nil
    empty_cond = nil

    begin
      reader = nil
      @lock.synchronize do
        unless @messages.empty?
          # fast path
          return @messages.shift
        else
          reader = Queue.new
          @readers.push reader
          if timeout
            mon = Monitor.new
            empty_cond = mon.new_cond

            timeout_thread = Thread.new do
              mon.synchronize do
                if empty_cond.wait(timeout)
                  # timeout
                  @lock.synchronize do
                    @readers.delete reader
                    reader << nil
                  end
                else
                  # timeout_thread was waked up before timeout
                end
              end
            end # thread
          end
        end
      end
      # either timeout or writer will send to us
      return reader.shift
    ensure
      # (try to) clean up timeout thread
      if timeout_thread
        mon.synchronize { empty_cond.signal }
        Thread.pass
      end
    end
  end
end

end
