10000.times do
  t1 = Time.mktime(2010,7,27)
  t2 = Time.mktime(2010,7,26,23,59,59,0.999999)

  unless (t1-t2) > 0
    puts "WHY?"
  end
end
