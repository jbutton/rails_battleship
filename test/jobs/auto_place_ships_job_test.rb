require "test_helper"

class AutoPlaceShipsJobTest < ActiveJob::TestCase
  include GameHelpers

  test "places missing fleets and starts the game" do
    game = start_matched_game
    game.board_for(players(:alice)).place_ships(fleet_in_rows)

    AutoPlaceShipsJob.perform_now(game.id)

    assert game.reload.in_progress?
    assert game.boards.all?(&:ready)
  end

  test "does nothing once the game has started" do
    game = start_battle
    assert_no_changes -> { game.reload.updated_at } do
      AutoPlaceShipsJob.perform_now(game.id)
    end
  end
end
