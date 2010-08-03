100000.times do
  now1=Time.now
  now2=Time.now
  if ((now2-now1)<0) 
    puts "now1: %d.%d" % [now1.sec, now1.usec]
    puts "now2: %d.%d" % [now2.sec, now1.usec]
  end
end
