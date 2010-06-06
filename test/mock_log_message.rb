class MockLogger
  def debug(str)
    #puts str
  end
  def info(str)
    #puts str
  end
  def warn(str)
    puts str
  end
  def error(str)
    puts str
  end
end

$logger = MockLogger.new
def log_message(msg)
  $logger.info(msg)
end

def log_warning(msg)
  $logger.warn(msg)
end

def log_error(msg)
  $logger.error(msg)
end

def log_info(msg)
  $logger.info(msg)
end

