require "baseclient"
require "kconv"

class TestBeforeAgree < BaseClient

  def test_before_agree_gote_logout
    login
    result  = cmd  "AGREE"
    result2 = cmd2 "LOGOUT"

    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)

    assert(/^REJECT/ =~ result)
    assert(/^REJECT/ =~ result2)
  end

  def test_before_agree_sente_logout
    login
    sleep 0.5
    result2 = cmd2 "AGREE"
    result  = cmd  "LOGOUT"

    result  += read_nonblock(@socket1)
    result2 += read_nonblock(@socket2)

    assert(/^REJECT/ =~ result)
    assert(/^REJECT/ =~ result2)
  end
end
