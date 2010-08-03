fname = File.join("/", "tmp", "test.txt")
if File.exist?(fname)
  File.rename(fname, fname+".rename")
end

10000.times do 
  time = Time.now
  File.new(fname, File::CREAT)
  mtime = File.stat(fname).mtime
  if mtime.to_i < time.to_i
    date = `/bin/date -R`
    p time
    p mtime
    p date
    puts "time:  %d.%d" % [time.sec,   time.usec]
    puts "mtime: %d.%d" % [mtime.sec, mtime.usec]
    exit 1
  end
  File.delete fname
end

