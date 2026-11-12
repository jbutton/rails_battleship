require "test_helper"

class ShotTest < ActiveSupport::TestCase
  include GameHelpers

  test "coordinates must be on the grid" do
    game = start_battle
    shot = game.shots.build(shooter: players(:alice), target_player: players(:bob), x: 10, y: 0, result: :miss)
    assert_not shot.valid?
  end

  test "the same cell cannot be shot twice" do
    game = start_battle
    attrs = { shooter: players(:alice), target_player: players(:bob), x: 3, y: 3, result: :miss }
    game.shots.create!(attrs)
    assert_not game.shots.build(attrs).valid?
  end
end
