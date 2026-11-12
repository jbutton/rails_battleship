require "test_helper"

class GameTest < ActiveSupport::TestCase
  include GameHelpers

  test "new games start waiting for players" do
    assert Game.new(player1: players(:alice)).waiting_for_players?
  end

  test "a player cannot play against themselves" do
    game = Game.new(player1: players(:alice), player2: players(:alice))
    assert_not game.valid?
  end

  test "opponent_of returns the other player" do
    game = start_matched_game
    assert_equal players(:bob), game.opponent_of(players(:alice))
    assert_equal players(:alice), game.opponent_of(players(:bob))
    assert_nil game.opponent_of(players(:carol))
  end

  test "switch_turn! hands the turn to the opponent" do
    game = start_battle
    game.switch_turn!
    assert game.my_turn?(players(:bob))
  end

  test "check_winner! finishes the game when a fleet is sunk" do
    game = start_battle
    bob_board = game.board_for(players(:bob))
    fleet_in_rows.flat_map { |s| s["coordinates"] }.each { |c| bob_board.process_shot(c["x"], c["y"]) }

    game.reload.check_winner!

    assert game.finished?
    assert_equal players(:alice), game.winner
  end
end
