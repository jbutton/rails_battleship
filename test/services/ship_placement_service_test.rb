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

  test "a submit racing the auto-place job does not overwrite the board or reset the turn" do
    in_flight = @game.board_for(players(:alice)) # loaded before the job ran
    AutoPlaceShipsJob.perform_now(@game.id)
    auto_placed_ships = in_flight.reload.ships_json
    @game.reload.update!(current_turn_player: players(:bob))

    stale = Board.find(in_flight.id).tap { |b| b.ready = false; b.game.state = "placing_ships" }
    result = GamePlay::ShipPlacementService.new(board: stale, ships_data: fleet_in_rows).call

    assert_not result[:success]
    assert_equal auto_placed_ships, in_flight.reload.ships_json
    assert @game.reload.my_turn?(players(:bob))
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
