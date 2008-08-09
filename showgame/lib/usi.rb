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
  return [:piece, player]
end

def parseBoard(word, board)
  x=9; y=1
  i = 0
  while (i < word.length)
    c = word[i]
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
    end
    i += 1
  end
end
