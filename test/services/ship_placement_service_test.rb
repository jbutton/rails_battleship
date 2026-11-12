require "test_helper"

class ShipPlacementServiceTest < ActiveSupport::TestCase
  include GameHelpers

  setup { @game = start_matched_game }

  def place(player, fleet = fleet_in_rows)
    GamePlay::ShipPlacementService.new(board: @game.board_for(player), ships_data: fleet).call
  end

  test "game starts once both players have placed" do
    assert place(players(:alice))[:success]
    assert @game.reload.placing_ships?

    assert place(players(:bob))[:success]
    assert @game.reload.in_progress?
    assert @game.my_turn?(players(:alice))
  end

  test "rejects an invalid fleet" do
    result = place(players(:alice), fleet_in_rows.first(2))
    assert_not result[:success]
  end

  test "rejects placement after the deadline" do
    @game.update!(ships_placement_deadline: 1.minute.ago)
    assert_match "expired", place(players(:alice))[:error]
  end
end
