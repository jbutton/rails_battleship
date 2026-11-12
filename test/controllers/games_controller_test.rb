require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "lobby requires a player" do
    get games_path
    assert_redirected_to new_player_path
  end

  test "joining creates a game and shows it" do
    sign_in_as("Dave")
    post join_game_path

    game = Game.last
    assert_redirected_to game_path(game)
    follow_redirect!
    assert_response :success
  end

  test "players can see their own game" do
    dave = sign_in_as("Dave")
    game = start_battle(dave, players(:bob))

    get game_path(game)
    assert_response :success
  end

  test "players cannot open someone else's game" do
    game = start_battle
    sign_in_as("Dave")

    get game_path(game)
    assert_redirected_to games_path
  end

  test "lobby offers a new match after a finished game" do
    dave = sign_in_as("Dave")
    game = start_battle(dave, players(:bob))
    game.update!(state: :finished, winner: dave)

    get games_path
    assert_select "button", text: "Find Opponent"
  end
end
