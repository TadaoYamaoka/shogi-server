require "baseclient"
require "kconv"

class TestBeforeAgree < BaseClient

  def test_gote_logout_after_sente_agree
    login
    result  = cmd  "AGREE"
    result2 = cmd2 "LOGOUT"

    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)

    assert(/^REJECT/ =~ result)
    assert(/^REJECT/ =~ result2)
  end

  def test_sente_logout_after_gote_agree
    login
    result2 = cmd2 "AGREE"
    result  = cmd  "LOGOUT"

    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)

    assert(/^REJECT/ =~ result)
    assert(/^REJECT/ =~ result2)
  end

  def test_gote_logout_before_sente_agree
    login
    result  = ""
    result2 = cmd2 "LOGOUT"

    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)

    assert(/^REJECT/ =~ result)
    assert(/^REJECT/ =~ result2)
  end

  def test_sente_logout_before_gote_agree
    login
    result2 = ""
    result  = cmd  "LOGOUT"

    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)

    assert(/^REJECT/ =~ result)
    assert(/^REJECT/ =~ result2)
  end
end
