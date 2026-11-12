require "test_helper"

class ShotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dave = sign_in_as("Dave")
    @game = start_battle(@dave, players(:bob))
  end

  test "firing on your turn" do
    post game_shots_path(@game), params: { x: 0, y: 0 }, as: :json

    assert_response :success
    assert_equal "hit", response.parsed_body["result"]
  end

  test "firing out of turn is rejected" do
    @game.update!(current_turn_player: players(:bob))
    post game_shots_path(@game), params: { x: 0, y: 0 }, as: :json

    assert_response :unprocessable_entity
    assert_equal "It's not your turn", response.parsed_body["error"]
  end

  test "outsiders cannot fire in a game" do
    other = start_battle(players(:alice), players(:carol))
    post game_shots_path(other), params: { x: 0, y: 0 }, as: :json

    assert_redirected_to games_path
  end
end
