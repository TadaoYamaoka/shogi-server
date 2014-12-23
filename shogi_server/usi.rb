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

      # 1 -> a
      # 2 -> b
      # ...
      # 9 -> i
      def danToAlphabet(int)
        return (int+96).chr
      end

      # a -> 1
      # b -> 2
      # ...
      # i -> 9
      def alphabetToDan(s)
        if RUBY_VERSION >= "1.9.1"
          # String.bytes is incompatible:
          #  - Ruby 1.9.3 String.bytes returns Enumerator
          #  - Ruby 2.1.0 String.bytes returns [Integer]
          return s.each_byte.next-96
        else
          return s[0]-96
        end
      end

      def csaPieceToUsi(csa, sente)
        str = ""
        case csa
        when "FU"
          str = "p"
        when "KY"
          str = "l"
        when "KE"
          str = "n"
        when "GI"
          str = "s"
        when "KI"
          str = "g"
        when "KA"
          str = "b"
        when "HI"
          str = "r"
        when "OU"
          str = "k"
        when "TO"
          str = "+p"
        when "NY"
          str = "+l"
        when "NK"
          str = "+n"
        when "NG"
          str = "+s"
        when "UM"
          str = "+b"
        when "RY"
          str = "+r"
        end
        return sente ? str.upcase : str
      end

      def usiPieceToCsa(str)
        ret = ""
        case str.downcase
        when "p"
          ret = "FU"
        when "l"
          ret = "KY"
        when "n"
          ret = "KE"
        when "s"
          ret = "GI"
        when "g"
          ret = "KI"
        when "b"
          ret = "KA"
        when "r"
          ret = "HI"
        when "+p"
          ret = "TO"
        when "+l"
          ret = "NY"
        when "+n"
          ret = "NK"
        when "+s"
          ret = "NG"
        when "+b"
          ret = "UM"
        when "+r"
          ret = "RY"
        when "k"
          ret = "OU"
        end
        return ret
      end

      def moveToUsi(move)
        str = ""
        if move.is_drop?
          str += "%s*%s%s" % [csaPieceToUsi(move.name, move.sente).upcase, move.x1, danToAlphabet(move.y1)]
        else
          str += "%s%s%s%s" % [move.x0, danToAlphabet(move.y0), move.x1, danToAlphabet(move.y1)]
          str += "+" if move.promotion
        end

        return str
      end

      def usiToCsa(str, board, sente)
        ret = ""
        if str[1..1] == "*" 
          # drop
          ret += "00%s%s%s" % [str[2..2], alphabetToDan(str[3..3]), usiPieceToCsa(str[0..0])]
        else
          from_x = str[0..0]
          from_y = alphabetToDan(str[1..1])
          ret += "%s%s%s%s" % [from_x, from_y, str[2..2], alphabetToDan(str[3..3])]
          csa_piece = board.array[from_x.to_i][from_y.to_i]
          if str.size == 5 && str[4..4] == "+"
            # Promoting move
            ret += csa_piece.promoted_name
          else
            ret += csa_piece.current_name
          end
        end
        return (sente ? "+" : "-") + ret
      end
    end # class methods

    # Convert USI moves to CSA one by one from the initial position
    #
    class UsiToCsa
      attr_reader :board, :csa_moves, :usi_moves

      # Constructor
      #
      def initialize
        @board = ShogiServer::Board.new
        @board.initial
        @sente = true
        @csa_moves = []
        @usi_moves = []
      end

      def deep_copy
        return Marshal.load(Marshal.dump(self))
      end

      # Parses a usi move string and returns an array of [move_result_state,
      # csa_move_string]
      #
      def next(usi)
        usi_moves << usi
        csa = Usi.usiToCsa(usi, @board, @sente)
        state = @board.handle_one_move(csa, @sente)
        @sente = !@sente
        @csa_moves << csa
        return [state, csa]
      end

    end # class UsiToCsa

    # Convert CSA moves to USI one by one from the initial position
    #
    class CsaToUsi
      attr_reader :board, :csa_moves, :usi_moves

      # Constructor
      #
      def initialize
        @board = ShogiServer::Board.new
        @board.initial
        @sente = true
        @csa_moves = []
        @usi_moves = []
      end

      def deep_copy
        return Marshal.load(Marshal.dump(self))
      end
      
      # Parses a csa move string and returns an array of [move_result_state,
      # usi_move_string]
      #
      def next(csa)
        csa_moves << csa
        state = @board.handle_one_move(csa, @sente)
        @sente = !@sente
        usi = Usi.moveToUsi(@board.move)
        @usi_moves << usi
        return [state, usi]
      end
    end # class CsaToUsi

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

      mapping = [[ShogiServer::PieceHI, "R"],
                 [ShogiServer::PieceKA, "B"],
                 [ShogiServer::PieceKI, "G"],
                 [ShogiServer::PieceGI, "S"],
                 [ShogiServer::PieceKE, "N"],
                 [ShogiServer::PieceKY, "L"],
                 [ShogiServer::PieceFU, "P"]]

      mapping.each do |klass, str|
        pieces = hands.find_all {|piece| piece.class == klass}
        unless pieces.empty?
          if pieces.size > 1 
            s += "%d" % [pieces.size]
          end
          s += str
        end
      end
      return s
    end

    # "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b -"
    #
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
      return s
    end

  end # class

end # module
