$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require 'test/unit'
require 'tempfile'
require 'mock_game'
require 'mock_log_message'
require 'test/mock_player'
require 'shogi_server/login'
require 'shogi_server/player'
require 'shogi_server/command'


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

  def event
    return "test"
  end

  def dir
    return $topdir
  end

  def get_player(status, game_id, sente, searcher)
    if sente == true
      $p1 = MockPlayer.new
      $p1.name = "p1"
      return $p1
    elsif sente == false
      $p2 = MockPlayer.new
      $p2.name = "p2"
      return $p2
    elsif sente == nil
      return nil
    else
      return nil
    end
  end
end


class TestFactoryMethod < Test::Unit::TestCase 

  def setup
    @p = MockPlayer.new
    @p.name = "test_factory_method_player"
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

  def test_monitor2on_command
    cmd = ShogiServer::Command.factory("%%MONITOR2ON game_id", @p)
    assert_instance_of(ShogiServer::Monitor2OnCommand, cmd)
  end

  def test_monitoroff_command
    cmd = ShogiServer::Command.factory("%%MONITOROFF game_id", @p)
    assert_instance_of(ShogiServer::MonitorOffCommand, cmd)
  end

  def test_monitor2off_command
    cmd = ShogiServer::Command.factory("%%MONITOR2OFF game_id", @p)
    assert_instance_of(ShogiServer::Monitor2OffCommand, cmd)
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

  def test_setbuoy_command
    cmd = ShogiServer::Command.factory("%%SETBUOY buoy_test-1500-0 +7776FU", @p)
    assert_instance_of(ShogiServer::SetBuoyCommand, cmd)
  end

  def test_setbuoy_command_with_counter
    cmd = ShogiServer::Command.factory("%%SETBUOY buoy_test-1500-0 +7776FU 3", @p)
    assert_instance_of(ShogiServer::SetBuoyCommand, cmd)
  end

  def test_deletebuoy_command
    cmd = ShogiServer::Command.factory("%%DELETEBUOY buoy_test-1500-0", @p)
    assert_instance_of(ShogiServer::DeleteBuoyCommand, cmd)
  end

  def test_getbuoycount_command
    cmd = ShogiServer::Command.factory("%%GETBUOYCOUNT buoy_test-1500-0", @p)
    assert_instance_of(ShogiServer::GetBuoyCountCommand, cmd)
  end

  def test_void_command
    cmd = ShogiServer::Command.factory("%%%HOGE", @p)
    assert_instance_of(ShogiServer::VoidCommand, cmd)
  end

  def test_error
    cmd = ShogiServer::Command.factory("should_be_error", @p)
    assert_instance_of(ShogiServer::ErrorCommand, cmd)
    cmd.call
    assert_match /unknown command should_be_error/, cmd.msg
  end

  def test_error_login
    cmd = ShogiServer::Command.factory("LOGIN hoge foo", @p)
    assert_instance_of(ShogiServer::ErrorCommand, cmd)
    cmd.call
    assert_no_match /unknown command LOGIN hoge foo/, cmd.msg

    cmd = ShogiServer::Command.factory("LOGin hoge foo", @p)
    assert_instance_of(ShogiServer::ErrorCommand, cmd)
    cmd.call
    assert_no_match /unknown command LOGIN hoge foo/, cmd.msg

    cmd = ShogiServer::Command.factory("LOGIN  hoge foo", @p)
    assert_instance_of(ShogiServer::ErrorCommand, cmd)
    cmd.call
    assert_no_match /unknown command LOGIN hoge foo/, cmd.msg

    cmd = ShogiServer::Command.factory("LOGINhoge foo", @p)
    assert_instance_of(ShogiServer::ErrorCommand, cmd)
    cmd.call
    assert_no_match /unknown command LOGIN hoge foo/, cmd.msg
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

  def test_call_read_logfile
    game = MockGame.new
    cmd = ShogiServer::MonitorOnCommand.new("%%MONITORON hoge", @p, game)
    rc = cmd.call
    assert_equal("##[MONITOR][dummy_game_id] dummy_game_show\n##[MONITOR][dummy_game_id] line1\n##[MONITOR][dummy_game_id] line2\n##[MONITOR][dummy_game_id] +OK\n", @p.out.join)
    assert_equal(:continue, rc)
  end
end

#
#
class TestMonitor2OnCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::Monitor2OnCommand.new("%%MONITOR2ON hoge", @p, nil)
    rc = cmd.call

    assert_equal(:continue, rc)
  end

  def test_call_read_logfile
    $tempfile = Tempfile.new("TC_command_test_call_read_logfile")
    $tempfile.write "hoge\nfoo\n"
    $tempfile.close
    game = MockGame.new
    def game.logfile
      $tempfile.path
    end
    cmd = ShogiServer::Monitor2OnCommand.new("%%MONITOR2ON hoge", @p, game)
    rc = cmd.call
    assert_equal("##[MONITOR2][dummy_game_id] hoge\n##[MONITOR2][dummy_game_id] foo\n##[MONITOR2][dummy_game_id] +OK\n", @p.out.join)
    assert_equal(:continue, rc)
    $tempfile = nil
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
class TestMonitor2OffCommand < Test::Unit::TestCase 
  def setup
    @p = MockPlayer.new
    @game = MockGame.new
    @p.game = @game
  end

  def test_call
    cmd = ShogiServer::Monitor2OffCommand.new("%%MONITOR2OFF hoge", @p, nil)
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

class BaseTestBuoyCommand < Test::Unit::TestCase
  def setup
    @p = MockPlayer.new
    $p1 = nil
    $p2 = nil

    delete_buoy_yaml
    @buoy = ShogiServer::Buoy.new
  end

  def teadown
    delete_buoy_yaml
  end

  def delete_buoy_yaml
    file = File.join($topdir, "buoy.yaml")
    File.delete file if File.exist? file
  end

  def test_dummy
    assert true
  end
end


#
#
class TestSetBuoyCommand < BaseTestBuoyCommand
  
  def setup
    super
    @p.name = "set_buoy_player"
  end

  def test_call_2
    assert @buoy.is_new_game?("buoy_hoge-1500-0")
    cmd = ShogiServer::SetBuoyCommand.new "%%SETBUOY", @p, "buoy_hoge-1500-0", "+7776FU", 2
    rt = cmd.call
    assert :continue, rt
    assert !@buoy.is_new_game?("buoy_hoge-1500-0")
    assert !$p1.out.empty?
    assert !$p2.out.empty?
    buoy_game2 = @buoy.get_game("buoy_hoge-1500-0")
    assert_equal ShogiServer::BuoyGame.new("buoy_hoge-1500-0", "+7776FU", @p.name, 1), buoy_game2
  end

  def test_call_1
    assert @buoy.is_new_game?("buoy_hoge-1500-0")
    cmd = ShogiServer::SetBuoyCommand.new "%%SETBUOY", @p, "buoy_hoge-1500-0", "+7776FU", 1
    rt = cmd.call
    assert :continue, rt
    assert @buoy.is_new_game?("buoy_hoge-1500-0")
    assert !$p1.out.empty?
    assert !$p2.out.empty?
  end

  def test_call_error_not_buoy_game_name
    assert @buoy.is_new_game?("buoy_hoge-1500-0")
    cmd = ShogiServer::SetBuoyCommand.new "%%SETBUOY", @p, "buoyhoge-1500-0", "+7776FU", 1
    rt = cmd.call
    assert :continue, rt
    assert !$p1
    assert !$p2
    assert @buoy.is_new_game?("buoy_hoge-1500-0")
  end

  def test_call_error_duplicated_game_name
    assert @buoy.is_new_game?("buoy_duplicated-1500-0")
    bg = ShogiServer::BuoyGame.new("buoy_duplicated-1500-0", ["+7776FU"], @p.name, 1)
    @buoy.add_game bg
    assert !@buoy.is_new_game?("buoy_duplicated-1500-0")
    
    cmd = ShogiServer::SetBuoyCommand.new "%%SETBUOY", @p, "buoy_duplicated-1500-0", "+7776FU", 1
    rt = cmd.call
    assert :continue, rt
    assert !$p1
    assert !$p2
    assert !@buoy.is_new_game?("buoy_duplicated-1500-0")
  end

  def test_call_error_bad_moves
    assert @buoy.is_new_game?("buoy_badmoves-1500-0")
    cmd = ShogiServer::SetBuoyCommand.new "%%SETBUOY", @p, "buoy_badmoves-1500-0", "+7776FU+8786FU", 1
    rt = cmd.call
    assert :continue, rt
    assert !$p1
    assert !$p2
    assert @buoy.is_new_game?("buoy_badmoves-1500-0")
  end

  def test_call_error_bad_counter
    assert @buoy.is_new_game?("buoy_badcounter-1500-0")
    cmd = ShogiServer::SetBuoyCommand.new "%%SETBUOY", @p, "buoy_badcounter-1500-0", "+7776FU", 0
    rt = cmd.call
    assert :continue, rt
    assert !$p1
    assert !$p2
    assert @buoy.is_new_game?("buoy_badcounter-1500-0")
  end
end


#
#
class TestDeleteBuoyCommand < BaseTestBuoyCommand
  def test_call
    buoy_game = ShogiServer::BuoyGame.new("buoy_testdeletebuoy-1500-0", "+7776FU", @p.name, 1)
    assert @buoy.is_new_game?(buoy_game.game_name)
    @buoy.add_game buoy_game
    assert !@buoy.is_new_game?(buoy_game.game_name)
    cmd = ShogiServer::DeleteBuoyCommand.new "%%DELETEBUOY", @p, buoy_game.game_name
    rt = cmd.call
    assert :continue, rt
    assert !$p1
    assert !$p2
    assert @buoy.is_new_game?(buoy_game.game_name)
  end

  def test_call_not_exist
    buoy_game = ShogiServer::BuoyGame.new("buoy_notexist-1500-0", "+7776FU", @p.name, 1)
    assert @buoy.is_new_game?(buoy_game.game_name)
    cmd = ShogiServer::DeleteBuoyCommand.new "%%DELETEBUOY", @p, buoy_game.game_name
    rt = cmd.call
    assert :continue, rt
    assert !$p1
    assert !$p2
    assert @buoy.is_new_game?(buoy_game.game_name)
  end

  def test_call_another_player
    buoy_game = ShogiServer::BuoyGame.new("buoy_anotherplayer-1500-0", "+7776FU", "another_player", 1)
    assert @buoy.is_new_game?(buoy_game.game_name)
    @buoy.add_game(buoy_game)
    assert !@buoy.is_new_game?(buoy_game.game_name)

    cmd = ShogiServer::DeleteBuoyCommand.new "%%DELETEBUOY", @p, buoy_game.game_name
    rt = cmd.call
    assert :continue, rt
    assert_equal "##[ERROR] you are not allowed to delete a buoy game that you did not set: buoy_anotherplayer-1500-0\n", @p.out.first
    assert !@buoy.is_new_game?(buoy_game.game_name)
  end
end

#
#
class TestGetBuoyCountCommand < BaseTestBuoyCommand
  def test_call
    buoy_game = ShogiServer::BuoyGame.new("buoy_testdeletebuoy-1500-0", "+7776FU", @p.name, 1)
    assert @buoy.is_new_game?(buoy_game.game_name)
    @buoy.add_game buoy_game
    assert !@buoy.is_new_game?(buoy_game.game_name)
    cmd = ShogiServer::GetBuoyCountCommand.new "%%GETBUOYCOUNT", @p, buoy_game.game_name
    rt = cmd.call
    assert :continue, rt
    assert_equal ["##[GETBUOYCOUNT] 1\n", "##[GETBUOYCOUNT] +OK\n"], @p.out
  end

  def test_call_not_exist
    buoy_game = ShogiServer::BuoyGame.new("buoy_notexist-1500-0", "+7776FU", @p.name, 1)
    assert @buoy.is_new_game?(buoy_game.game_name)
    cmd = ShogiServer::GetBuoyCountCommand.new "%%GETBUOYCOUNT", @p, buoy_game.game_name
    rt = cmd.call
    assert :continue, rt
    assert_equal ["##[GETBUOYCOUNT] -1\n", "##[GETBUOYCOUNT] +OK\n"], @p.out
  end
end

#
#
class TestMonitorHandler < Test::Unit::TestCase
  def test_not_equal_players
    @player1 = MockPlayer.new
    @handler1 = ShogiServer::MonitorHandler1.new @player1
    @player2 = MockPlayer.new
    @handler2 = ShogiServer::MonitorHandler1.new @player2

    assert_not_equal(@handler1, @handler2)
  end

  def test_equal
    @player1 = MockPlayer.new
    @handler1 = ShogiServer::MonitorHandler1.new @player1
    @handler2 = ShogiServer::MonitorHandler1.new @player1

    assert_equal(@handler1, @handler2)
  end
end

#
#
class TestMonitorHandler1 < Test::Unit::TestCase
  def setup
    @player = MockPlayer.new
    @handler = ShogiServer::MonitorHandler1.new @player
  end

  def test_type
    assert_equal(1, @handler.type)
  end

  def test_header
    assert_equal("MONITOR", @handler.header)
  end
  
  def test_equal
    assert_equal @handler, @handler
    assert_not_equal @handler, nil
  end

  def test_not_equal
    assert_not_equal(@handler, ShogiServer::MonitorHandler2.new(@player))
  end

  def test_write_safe
    @handler.write_safe("game_id", "hoge")
    assert_equal("##[MONITOR][game_id] hoge\n##[MONITOR][game_id] +OK\n", 
                 @player.out.join)
  end
end

#
#
class TestMonitorHandler2 < Test::Unit::TestCase
  def setup
    @player = MockPlayer.new
    @handler = ShogiServer::MonitorHandler2.new @player
  end

  def test_type
    assert_equal(2, @handler.type)
  end

  def test_header
    assert_equal("MONITOR2", @handler.header)
  end

  def test_equal
    assert_equal @handler, @handler
    assert_not_equal @handler, nil
  end

  def test_not_equal
    assert_not_equal(@handler, ShogiServer::MonitorHandler1.new(@player))
  end

  def test_write_safe
    @handler.write_safe("game_id", "hoge")
    assert_equal("##[MONITOR2][game_id] hoge\n##[MONITOR2][game_id] +OK\n", 
                 @player.out.join)
  end

  def test_write_safe2
    @handler.write_safe("game_id", "hoge\nfoo")
    assert_equal("##[MONITOR2][game_id] hoge\n##[MONITOR2][game_id] foo\n##[MONITOR2][game_id] +OK\n", 
                 @player.out.join)
  end
end

