$:.unshift File.join(File.dirname(__FILE__), "..")
load 'mk_rate'
require 'test/unit'

class RatingTest < Test::Unit::TestCase
  def test_rating1
    wl = GSL::Matrix[[0,3,9],
                [1,0,3],
                [1,1,0]]
    rating = Rating.new(wl)
    rating.rating
    rating.average!
    rating.integer!
    assert( rating.rate[0] > rating.rate[1])
    assert( rating.rate[1] > rating.rate[2])
  end

  def test_rating2
    wl = GSL::Matrix[ # 週刊将棋2001年9月12日号のデータ
      [  0,  59,  52,  39,  29,  12],    # 名人およびA級
      [ 40,   0,  37,  29,  27,  10],    # B級1組
      [ 33,  35,   0,  50,  92,  41],    # B級2組
      [ 21,  19,  51,   0, 140,  80],    # C級1組
      [  5,  21,  82, 103,   0, 124],    # C級2組
      [  2,   6,   9,  34,  44,   0],    # フリークラス
    ]
    rating = Rating.new(wl)
    assert_nothing_raised {rating.rating}
    rating.integer!
    p1, p2, p3, p4, p5, p6 = rating.rate.to_a
    assert(p1 > p2)
    assert(p2 > p3)
    assert(p3 > p4)
    assert(p4 > p5)
    assert(p5 > p6)
  end

  def test_rating3
    wl = GSL::Matrix[[0, 3, 18], 
                [1, 0, 14], 
                [10, 39, 0]]
    rating = Rating.new(wl)
    assert_nothing_raised {rating.rating}
    rating.integer!
    p1, p2, p3 = rating.rate.to_a
    assert( p1 > p2 )
    assert( p3 > p2 )
  end

  def test_rank2
    wl = GSL::Matrix[[0, 3],
                [1, 0]]
    rating = Rating.new(wl)
    rating.rating
    p1 = rating.rate[0]
    p2 = rating.rate[1]
    rating.integer!
    assert( (180..200).include?(p1 - p2), rating.rate.to_a.inspect )
  end

  def test_rank3
    wl = GSL::Matrix[[0, 30, 0],
                [10, 0, 30],
                [0, 10, 0]]
    rating = Rating.new(wl)
    rating.rating
    rating.average!
    rating.integer!
    p1 = rating.rate[0]
    p2 = rating.rate[1]
    rating.integer!
    assert( rating.rate[0] > rating.rate[1])
    assert( rating.rate[1] > rating.rate[2])
  end
end


class TestWinLossMatrix < Test::Unit::TestCase
  def setup
    keys = ['a', 'b', 'c']
    win_loss = GSL::Matrix[[0,2,3],[1,0,1],[1,1,0]]
    @matrix = WinLossMatrix.new(keys, win_loss)
  end
    
  def test_delete_row
    new_matrix = @matrix.delete_row(1)
    assert_equal(3, @matrix.size)
    assert_equal(2, new_matrix.size)
    assert_equal(['a','c'], new_matrix.keys)
    assert_equal(GSL::Matrix[[0,3],[1,0]], new_matrix.matrix)
  end

  def test_delete_rows
    $deleted = []
    def @matrix.delete_row(index)
      $deleted << index
      self
    end
    @matrix.delete_rows([0,1])
    assert_equal([1,0], $deleted)
  end

  def test_connected_subsets
    array = %w!
      0  0  0  0  0  2  9 74  0  0  0
      0  0  0  0 21  0  0  0  0  0  0
      0  0  0  0 19  0  0  0  0  0  0
      0  0  0  0 13  0  0  0  0  0  0
      0 19 20 27  0  0  0  0  0  0  0
      1  0  0  0  0  0  0  0  0  0  5
      1  0  0  0  0  0  0  0  0  0  9
      5  0  0  0  0  0  0  0  0  0  0
      0  0  0  0  0  0  0  0  0  0  6
      0  0  0  0  0  0  0  0  0  0  1
      0  0  0  0  0  1  1  0 28  1  0!.map{|v| v.to_i}
    keys = ["gps+11648e4e66e7ed6a86cb7f1d0cf604fe", 
            "gps1_wPrBn_hand+cf51828e1e4351eea9a70e754b8e5edc",
            "gps1_wPrBn_simple+d6c7d5e4acfb4a21072824d3be07c6dc",
            "gps1_woPrBn+ea563881afd2e56d3dd715538d2da850",
            "gps2_wPrBn_mem+dbd8165c47a193b7e76fa9adb3b4e445",
            "gps32+aa0ba6bfbd84caa7ef1cda34562ce90c",
            "gps500+0706915e56798d393c9aec4749789b2f",
            "guest+068b4eb12b042a72e1c7791344175d82",
            "guest+471a3f6aea2804130b5b967e8a42ea3c",
            "kaneko+4cee2e6a81fea84316b13626e705e431",
            "yowai_gps+95908f6c18338f5340371f71523fc5e3"]
    win_loss = GSL::Matrix.alloc(array, 11, 11)
    obj = WinLossMatrix.new(keys, win_loss)
    objs = obj.connected_subsets
    assert_equal(2, objs.size)
  end
end

# vim: ts=2 sw=2 sts=0

