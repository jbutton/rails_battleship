require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dave = sign_in_as("Dave")
    @game = start_matched_game(@dave, players(:bob))
  end

  def place(board, fleet = fleet_in_rows)
    patch board_path(board), params: { ships_data: fleet.to_json }, as: :turbo_stream
  end

  test "placing ships shows the waiting screen" do
    place(@game.board_for(@dave))

    assert_response :success
    assert_match "waiting-for-opponent", response.body
    assert @game.board_for(@dave).ready?
  end

  test "an invalid fleet shows an error" do
    place(@game.board_for(@dave), fleet_in_rows.first(2))

    assert_match "Invalid ship placement", response.body
    assert_not @game.board_for(@dave).ready?
  end

  test "cannot place ships on the opponent's board" do
    place(@game.board_for(players(:bob)))

    assert_redirected_to games_path
    assert_not @game.board_for(players(:bob)).ready?
  end
end
