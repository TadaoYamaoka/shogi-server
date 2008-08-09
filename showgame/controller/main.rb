# Default url mappings are:
#  a controller called Main is mapped on the root of the site: /
#  a controller called Something is mapped on: /something
# If you want to override this, add a line like this inside the class
#  map '/otherurl'
# this will force the controller to be mounted on: /otherurl

require File.join(__DIR__, "..", "..", "shogi_server", "piece")
require File.join(__DIR__, "..", "..", "shogi_server", "piece_ky")
require File.join(__DIR__, "..", "..", "shogi_server", "board")
require File.join(__DIR__, "..", "..", "shogi_server", "usi")

$pos2img = "/home/daigo/cprojects/gpsshogi/gps/sample/graphic/pos2img"
$pos2img_out_dir = File.join(".", "public", "images")

class MainController < Ramaze::Controller
  layout '/page'

  # the index action is called automatically when no other action is specified
  def index
    @title = "Welcome to Ramaze!"
  end

  def game(csa_file)
    csa_file.gsub!(" ", "+")
    dir = "/home/daigo/rubyprojects/shogi-server"
    files = Dir.glob(File.join(dir, "**", csa_file))
    if files.empty?
      redirect Rs()
    end
    board = ShogiServer::Board.new
    board.initial
    @moves = Array.new
    teban = true
    usi = ShogiServer::Usi.new
    kifu = File.open(files.first) {|f| f.read}
    kifu.each_line do |line|
      #  Ramaze::Log.warn(line)
      if /^([\+\-])(\d)(\d)(\d)(\d)([A-Z]{2})/ =~ line
        board.handle_one_move(line)
        sfen = usi.board2usi(board, teban)
        sfen = ShogiServer::Usi.escape(sfen)
        @moves << A(h(line), :href => Rs(:sfen, u(sfen)))
        teban = teban ? false : true
      end
    end
  end

  def sfen(str)
    sfen = "sfen %s" % [ShogiServer::Usi.unescape(str)]
    Ramaze::Log.warn(sfen)
    result = system($pos2img, "--dir", $pos2img_out_dir, sfen)
    Ramaze::Log.warn("result fail") unless result
    @img = "/images/%s.png" % [str]
  end

  # the string returned at the end of the function is used as the html body
  # if there is no template for the action. if there is a template, the string
  # is silently ignored
  def notemplate
    "there is no 'notemplate.xhtml' associated with this action"
  end
end
