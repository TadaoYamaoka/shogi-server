module ShogiServer # for a namespace

  class Usi
    class << Usi
      def escape(str)
        str.gsub("/", "_").
            gsub("+", "@").
            gsub(" ", ".")
      end

      def unescape(str)
        str.gsub("_", "/").
            gsub("@", "+").
            gsub(".", " ")
      end
    end

    def charToPiece(c)
      player = nil
      case c
      when /[A-Z]/
        player = true
      when /[a-z]/
        player = false
      end

      piece = nil
      case c.upcase
      when 'P' 
        piece = PieceFU
      when 'L' 
        piece = PieceKY
      when 'N' 
        piece = PieceKE
      when 'S' 
        piece = PieceGI
      when 'G' 
        piece = PieceKI
      when 'B' 
        piece = PieceKA
      when 'R' 
        piece = PieceHI
      when 'K' 
        piece = PieceOU
      end
      return [piece, player]
    end

    def piece2char(piece)
      s = ""
      case piece
      when PieceFU
        s = 'P'
      when PieceKY
        s = 'L'
      when PieceKE
        s = 'N'
      when PieceGI
        s = 'S'
      when PieceKI
        s = 'G'
      when PieceKA
        s = 'B'
      when PieceHI
        s = 'R'
      when PieceOU
        s = 'K'
      end
      s.downcase! if !piece.sente
      if piece.promoted
        s = "+%s" % [s]
      end
      return s
    end

    def parseBoard(word, board)
      x=9; y=1
      i = 0
      while (i < word.length)
        c = word[i,1]
        case c
        when /[a-zA-Z]/
          piece, player = charToPiece(c)
          piece.new(board, x, y, player)
          x -= 1
        when "+"
          cc = word[i+i]
          piece, player = charToPiece(cc)
          piece.new(board, x, y, player, true)
          x -= 1
          i += 1
        when /\d/
          x -= c.to_i
        when "/"
          x = 9
          y += 1
        else
          return 1
        end
        i += 1
      end
      return 0
    end

    def hands2usi(hands) 
      return "" if hands.empty?
      s = ""

      mapping = [[ShogiServer::PieceHi, R],
                 [ShogiServer::PieceKA, B],
                 [ShogiServer::PieceKI, G],
                 [ShogiServer::PieceGI, S],
                 [ShogiServer::PieceKE, N],
                 [ShogiServer::PieceKY, L],
                 [ShogiServer::PieceFU, P]]

      mapping.each do |klass, str|
        pieces = hands.find_all {|piece| piece === klass}
        unless pieces.empty?
          if pieces.size > 1 
            s += "%d" [pieces.size]
          end
          s += str
        end
      end
    end

    def board2usi(board, turn)
      s = ""
      for y in 1..9
        skip = 0
        9.downto(1) do |x| 
          piece = board.array[x][y]
          case piece 
          when nil
            skip += 1
          when ShogiServer::Piece
            if skip > 0
              s += skip.to_s
              skip = 0
            end
            s += piece2char(piece)
          end
        end
        if skip > 0
          s += skip.to_s
        end
        s += "/" if y < 9
      end
      s += " "
      if turn
        s += "b"
      else
        s += "w"
      end
      s += " "
      if board.sente_hands.empty? && board.gote_hands.empty?
        return s += "-"
      end
      s += hands2usi(board.sente_hands).upcase
      s += hands2usi(board.gote_hands).downcase
    end
  end # class

end # module
