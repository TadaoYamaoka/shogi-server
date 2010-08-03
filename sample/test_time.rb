require 'time'

class Time

  @@offset = Time.now - Time.mktime(Time.now.year, Time.now.month, Time.now.day+1) + 10
  class << self
    alias :orig_now :now
    def now
      return orig_now - @@offset
    end
  end

#  def initialize
#    super
#=begin
#    if @@offset == 0
#      current = Time.orig_now
#      @@offset = current - Time.mk_time(current.year, current.month, current.day)
#    end
#=end
#  end

end

if $0 == __FILE__
  puts Time.now
  sleep 1
  puts Time.now
end
