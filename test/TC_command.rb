$:.unshift File.join(File.dirname(__FILE__), "..")
require 'test/unit'
require 'shogi_server/login'
require 'shogi_server/player'
require 'shogi_server/command'

def log_warning(str)
  $stderr.puts str
end

def log_error(str)
  $stderr.puts str
end

class MockPlayer < ShogiServer::BasicPlayer
  attr_reader :out
  attr_accessor :game, :status, :protocol
  attr_accessor :game_name

  def initialize
    @out      = []
    @game     = nil
    @status   = nil
    @protocol = nil
    @game_name = "dummy_game_name"
  end

  def write_safe(str)
    @out << str
  end
end

class MockGame
  attr_accessor :finish_flag
  attr_reader :log
  attr_accessor :prepared_expire
  attr_accessor :rejected
  attr_accessor :is_startable_status
  attr_accessor :started
  attr_accessor :game_id

  def initialize
    @finish_flag     = false
    @log             = []
    @prepared_expire = false
    @rejected        = false
    @is_startable_status = false
    @started             = false
    @game_id         = "dummy_game_id"
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
    return "dummy_game_show"
  end

  def monitoron(player)
    @monitoron_called = true
  end

  def monitoroff(player)
    @monitoroff_called = true
  end
end

class MockLeague
  def initialize
    @games = {}
    @games["dummy_game_id"] = MockGame.new
  end

  def games
    return @games
  end

  def rated_players
    return []
  end

  def players
    return [MockPlayer.new]
  end
end


class TestFactoryMethod < Test::Unit::TestCase 

  def setup
    @p = MockPlayer.new
    $league = MockLeague.new
  end

  def test_keep_alive_command
    cmd = ShogiServer::Command.factory("", @p)
    assert_instance_of(ShogiServer::KeepAliveCommand, cmd)
  end

  def test_move_command
    cmd = ShogiServer::Command.factory("+7776FU", @p)
    assert_instance_of(ShogiServer::MoveCommand, cmd)
  end

  def test_special_command
    cmd = ShogiServer::Command.factory("%TORYO", @p)
    assert_instance_of(ShogiServer::SpecialCommand, cmd)
  end

  def test_special_command_timeout
    cmd = ShogiServer::Command.factory(:timeout, @p)
    assert_instance_of(ShogiServer::SpecialCommand, cmd)
  end

  def test_execption_command
    cmd = ShogiServer::Command.factory(:exception, @p)
    assert_instance_of(ShogiServer::ExceptionCommand, cmd)
  end

  def test_reject_command
    cmd = ShogiServer::Command.factory("REJECT", @p)
    assert_instance_of(ShogiServer::RejectCommand, cmd)
  end

  def test_agree_command
    cmd = ShogiServer::Command.factory("AGREE", @p)
    assert_instance_of(ShogiServer::AgreeCommand, cmd)
  end

  def test_show_command
    cmd = ShogiServer::Command.factory("%%SHOW game_id", @p)
    assert_instance_of(ShogiServer::ShowCommand, cmd)
  end

  def test_monitoron_command
    cmd = ShogiServer::Command.factory("%%MONITORON game_id", @p)
    assert_instance_of(ShogiServer::MonitorOnCommand, cmd)
  end

  def test_monitoroff_command
    cmd = ShogiServer::Command.factory("%%MONITOROFF game_id", @p)
    assert_instance_of(ShogiServer::MonitorOffCommand, cmd)
  end

  def test_help_command
    cmd = ShogiServer::Command.factory("%%HELP", @p)
    assert_instance_of(ShogiServer::HelpCommand, cmd)
  end

  def test_rating_command
    cmd = ShogiServer::Command.factory("%%RATING", @p)
    assert_instance_of(ShogiServer::RatingCommand, cmd)
  end

  def test_version_command
    cmd = ShogiServer::Command.factory("%%VERSION", @p)
    assert_instance_of(ShogiServer::VersionCommand, cmd)
  end

  def test_game_command
    cmd = ShogiServer::Command.factory("%%GAME", @p)
    assert_instance_of(ShogiServer::GameCommand, cmd)
  end

  def test_game_challenge_command_game
    cmd = ShogiServer::Command.factory("%%GAME default-1500-0 +", @p)
    assert_instance_of(ShogiServer::GameChallengeCommand, cmd)
  end

  def test_game_challenge_command_challenge
    cmd = ShogiServer::Command.factory("%%CHALLENGE default-1500-0 -", @p)
    assert_instance_of(ShogiServer::GameChallengeCommand, cmd)
  end

  def test_chat_command
    cmd = ShogiServer::Command.factory("%%CHAT hello", @p)
    assert_instance_of(ShogiServer::ChatCommand, cmd)
  end

  def test_list_command
    cmd = ShogiServer::Command.factory("%%LIST", @p)
    assert_instance_of(ShogiServer::ListCommand, cmd)
  end

  def test_who_command
    cmd = ShogiServer::Command.factory("%%WHO", @p)
    assert_instance_of(ShogiServer::WhoCommand, cmd)
  end

  def test_logout_command
    cmd = ShogiServer::Command.factory("LOGOUT", @p)
    assert_instance_of(ShogiServer::LogoutCommand, cmd)
  end

  def test_challenge_command
    cmd = ShogiServer::Command.factory("CHALLENGE", @p)
    assert_instance_of(ShogiServer::ChallengeCommand, cmd)
  end

  def test_space_command
    cmd = ShogiServer::Command.factory(" ", @p)
    assert_instance_of(ShogiServer::SpaceCommand, cmd)
  end

  def test_error
    cmd = ShogiServer::Command.factory("should_be_error", @p)
    assert_instance_of(ShogiServer::ErrorCommand, cmd)
  end
end

#
#
class TestKeepAliveCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
  end

  def test_call
    cmd = ShogiServer::KeepAliveCommand.new("", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
  end
end

#
#
class TestMoveCommand < Test::Unit::TestCase
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
    @p.status = "game"
  end

  def test_call
    cmd = ShogiServer::MoveCommand.new("+7776FU", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
  end

  def test_comment
    cmd = ShogiServer::MoveCommand.new("+7776FU,'comment", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
    assert_equal("'*comment", @game.log.first)
  end

  def test_x1_return
    @game.finish_flag = true
    @p.protocol = ShogiServer::LoginCSA::PROTOCOL
    cmd = ShogiServer::MoveCommand.new("+7776FU", @p)
    rc = cmd.call
    assert_equal(:return, rc)
  end
end

#
#
class TestSpecialComand < Test::Unit::TestCase
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
    @p.status = "game"
  end

  def test_toryo
    @game.finish_flag = true
    cmd = ShogiServer::SpecialCommand.new("%TORYO", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
  end

  def test_toryo_csa_protocol
    @game.finish_flag = true
    @p.protocol = ShogiServer::LoginCSA::PROTOCOL
    cmd = ShogiServer::SpecialCommand.new("%TORYO", @p)
    rc = cmd.call
    assert_equal(:return, rc)
  end

  def test_timeout
    cmd = ShogiServer::SpecialCommand.new(:timeout, @p)
    rc = cmd.call
    assert_equal(:continue, rc)
  end

  def test_expired_game
    @p.status = "agree_waiting"
    @game.prepared_expire = true
    assert(!@game.rejected)
    cmd = ShogiServer::SpecialCommand.new(:timeout, @p)
    rc = cmd.call
    assert_equal(:continue, rc)
    assert(@game.rejected)
  end

  def test_expired_game_csa_protocol
    @p.protocol = ShogiServer::LoginCSA::PROTOCOL
    @p.status = "agree_waiting"
    @game.prepared_expire = true
    assert(!@game.rejected)
    cmd = ShogiServer::SpecialCommand.new(:timeout, @p)
    rc = cmd.call
    assert_equal(:return, rc)
    assert(@game.rejected)
  end

  def test_error
    @p.status = "should_be_ignored"
    cmd = ShogiServer::SpecialCommand.new(:timeout, @p)
    rc = cmd.call
    assert_equal(:continue, rc)
  end
end

#
#
class TestExceptionCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
  end

  def test_call
    cmd = ShogiServer::ExceptionCommand.new(:exception, @p)
    rc = cmd.call
    assert_equal(:return, rc)
  end
end

#
#
class TestRejectCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
    @p.status = "game"
  end

  def test_call
    @p.status = "agree_waiting"
    assert(!@game.rejected)
    cmd = ShogiServer::RejectCommand.new("REJECT", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
    assert(@game.rejected)
  end

  def test_call_csa_protocol
    @p.protocol = ShogiServer::LoginCSA::PROTOCOL
    @p.status = "agree_waiting"
    assert(!@game.rejected)
    cmd = ShogiServer::RejectCommand.new("REJECT", @p)
    rc = cmd.call

    assert_equal(:return, rc)
    assert(@game.rejected)
  end

  def test_error
    @p.status = "should_be_ignored"
    cmd = ShogiServer::RejectCommand.new("REJECT", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
    assert(!@game.rejected)
  end
end

#
#
class TestAgreeCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
    @p.status = "agree_waiting"
  end

  def test_not_start_yet
    cmd = ShogiServer::AgreeCommand.new("AGREE", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
    assert(!@game.started)
  end

  def test_start
    @game.is_startable_status = true
    cmd = ShogiServer::AgreeCommand.new("AGREE", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
    assert(@game.started)
  end

  def test_error
    @p.status = "should_be_ignored"
    cmd = ShogiServer::AgreeCommand.new("AGREE", @p)
    rc = cmd.call
    assert_equal(:continue, rc)
    assert(!@game.started)
  end
end

#
#
class TestShowCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::ShowCommand.new("%%SHOW hoge", @p, @game)
    rc = cmd.call

    assert_equal(:continue, rc)
  end

  def test_call_nil_game
    cmd = ShogiServer::ShowCommand.new("%%SHOW hoge", @p, nil)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestMonitorOnCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::MonitorOnCommand.new("%%MONITORON hoge", @p, nil)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestMonitorOffCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::MonitorOffCommand.new("%%MONITOROFF hoge", @p, nil)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestHelpCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::HelpCommand.new("%%HELP", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestRatingCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    players = [MockPlayer.new]
    cmd = ShogiServer::RatingCommand.new("%%RATING", @p, players)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestVersionCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::VersionCommand.new("%%VERSION", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestGameCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call_connected
    @p.status = "connected"
    cmd = ShogiServer::GameCommand.new("%%GAME", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
    assert_equal("connected", @p.status)
  end

  def test_call_game_waiting
    @p.status = "game_waiting"
    cmd = ShogiServer::GameCommand.new("%%GAME", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
    assert_equal("connected", @p.status)
  end

  def test_call_agree_waiting
    @p.status = "agree_waiting"
    cmd = ShogiServer::GameCommand.new("%%GAME", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
    assert_equal("agree_waiting", @p.status)
  end
end

#
#
class TestChatCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    players = [["dummy_name", MockPlayer.new]]
    cmd = ShogiServer::ChatCommand.new("%%CHAT hoge", @p, "dummy message", players)
    rc = cmd.call

    assert_equal(:continue, rc)
  end

  def test_call_csa_protocol
    players = [["dummy_name", MockPlayer.new]]
    players.each do |name, p|
      p.protocol = ShogiServer::LoginCSA::PROTOCOL
    end
    cmd = ShogiServer::ChatCommand.new("%%CHAT hoge", @p, "dummy message", players)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestListCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    games = [["dummy_game_id", MockGame.new]]
    cmd = ShogiServer::ListCommand.new("%%LIST", @p, games)
    rc = cmd.call

    assert_equal(:continue, rc)
  end

end

#
#
class TestWhoCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    players = [["dummy_name", MockPlayer.new]]
    cmd = ShogiServer::WhoCommand.new("%%LIST", @p, players)
    rc = cmd.call

    assert_equal(:continue, rc)
  end

end

#
#
class TestLogoutCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::LogoutCommand.new("LOGOUT", @p)
    rc = cmd.call

    assert_equal(:return, rc)
  end

end

#
#
class TestChallengeCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
  end

  def test_call
    cmd = ShogiServer::ChallengeCommand.new("CHALLENGE", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestSpaceCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
  end

  def test_call
    cmd = ShogiServer::SpaceCommand.new("", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end

#
#
class TestErrorCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
  end

  def test_call
    cmd = ShogiServer::ErrorCommand.new("", @p)
    rc = cmd.call

    assert_equal(:continue, rc)
  end
end


