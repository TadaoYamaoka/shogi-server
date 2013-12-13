$:.unshift File.join(File.dirname(__FILE__), "..")
$topdir = File.expand_path File.dirname(__FILE__)
require "test/baseclient"
require "kconv"

class TestBeforeAgree < BaseClient

  def test_gote_logout_after_sente_agree
    login

    @p1.puts "AGREE"
    sleep 0.1
    @p2.puts "LOGOUT"
    @p1.wait /^REJECT/
    @p2.wait /^REJECT/
    assert true
  end

  def test_sente_logout_after_gote_agree
    login

    @p2.puts "AGREE"
    sleep 0.1
    @p1.puts "LOGOUT"
    @p1.wait /^REJECT/
    @p2.wait /^REJECT/
    assert true
  end

  def test_gote_logout_before_sente_agree
    login

    sleep 0.1
    @p2.puts "LOGOUT"
    @p1.wait /^REJECT/
    @p2.wait /^REJECT/
    assert true
  end

  def test_sente_logout_before_gote_agree
    login

    sleep 0.1
    @p1.puts "LOGOUT"
    @p1.wait /^REJECT/
    @p2.wait /^REJECT/
    assert true
  end
end
