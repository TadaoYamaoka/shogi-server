require 'shogi_server/piece'

module ShogiServer

class PieceKY  < Piece
  def initialize(*arg)
    @point = 1
    @normal_moves = []
    @promoted_moves = [[0, +1], [+1, +1], [-1, +1], [+1, +0], [-1, +0], [0, -1]]
    @name = "KY"
    @promoted_name = "NY"
    super
  end
  def room_of_head?(x, y, name)
    if (name == "KY")
      if (@sente)
        return false if (y == 1)
      else
        return false if (y == 9)
      end
    end
    return true
  end
  def far_movable_grids
    grids = Array::new
    if (@promoted)
      return []
    else
      if (@sente)                 # up
        cand_x = @x
        cand_y = @y - 1
        while (jump_to?(cand_x, cand_y))
          grids.push([cand_x, cand_y])
          break if (! put_to?(cand_x, cand_y))
          cand_y = cand_y - 1
        end
      else                        # down
        cand_x = @x
        cand_y = @y + 1
        while (jump_to?(cand_x, cand_y))
          grids.push([cand_x, cand_y])
          break if (! put_to?(cand_x, cand_y))
          cand_y = cand_y + 1
        end
      end
      return grids
    end
  end
end

end
