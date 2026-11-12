require "test_helper"

class FireShotServiceTest < ActiveSupport::TestCase
  include GameHelpers

  setup { @game = start_battle }

  test "a hit is recorded and the turn passes" do
    result = fire(@game, players(:alice), 0, 0)

    assert result[:success]
    assert_equal :hit, result[:result]
    assert @game.reload.my_turn?(players(:bob))
  end

  test "cannot fire out of turn" do
    result = fire(@game, players(:bob), 0, 0)
    assert_equal "It's not your turn", result[:error]
  end

  test "cannot fire at the same cell twice" do
    fire(@game, players(:alice), 5, 5)
    fire(@game, players(:bob), 5, 5)

    assert_match "Already shot", fire(@game, players(:alice), 5, 5)[:error]
  end

  test "sinking the last ship wins the game" do
    targets = fleet_in_rows.flat_map { |s| s["coordinates"] }
    misses = (0...Board::GRID_SIZE).flat_map { |x| (5...Board::GRID_SIZE).map { |y| [ x, y ] } }

    targets.each_with_index do |c, i|
      assert fire(@game, players(:alice), c["x"], c["y"])[:success]
      break if @game.reload.finished?
      assert fire(@game, players(:bob), *misses[i])[:success]
    end

    assert @game.reload.finished?
    assert_equal players(:alice), @game.winner
  end
end
