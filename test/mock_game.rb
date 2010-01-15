class MockGame
  attr_accessor :finish_flag
  attr_reader :log
  attr_accessor :prepared_expire
  attr_accessor :rejected
  attr_accessor :is_startable_status
  attr_accessor :started
  attr_accessor :game_id
  attr_accessor :game_name

  def initialize
    @finish_flag     = false
    @log             = []
    @prepared_expire = false
    @rejected        = false
    @is_startable_status = false
    @started             = false
    @game_id         = "dummy_game_id"
    @game_name       = "mock_game_name"
    @monitoron_called = false
    @monitoroff_called = false
  end

  def handle_one_move(move, player)
    return @finish_flag
  end

  def log_game(str)
    @log << str
  end

  def prepared_expire?
    return @prepared_expire
  end

  def reject(str)
    @rejected = true
  end

  def is_startable_status?
    return @is_startable_status
  end

  def start
    @started = true
  end

  def show
    return "dummy_game_show\nline1\nline2\n"
  end

  def monitoron(player)
    @monitoron_called = true
  end

  def monitoroff(player)
    @monitoroff_called = true
  end
end

