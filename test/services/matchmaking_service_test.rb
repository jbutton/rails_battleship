require "test_helper"

class MatchmakingServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include GameHelpers

  test "first player creates a waiting game" do
    game = GamePlay::MatchmakingService.new(players(:alice)).call

    assert game.waiting_for_players?
    assert players(:alice).reload.searching?
  end

  test "second player joins and starts ship placement" do
    game = nil
    assert_enqueued_with(job: AutoPlaceShipsJob) { game = start_matched_game }

    assert game.placing_ships?
    assert_equal players(:bob), game.player2
    assert_equal 2, game.boards.count
    assert game.ships_placement_deadline.future?
  end

  test "joining twice returns the same game instead of matching with yourself" do
    first = GamePlay::MatchmakingService.new(players(:alice)).call
    second = GamePlay::MatchmakingService.new(players(:alice).reload).call

    assert_equal first, second
    assert_nil second.player2
  end

  test "a player whose last game finished can find a new one" do
    old = start_battle
    old.update!(state: :finished, winner: players(:alice))

    game = GamePlay::MatchmakingService.new(players(:alice).reload).call
    assert_not_equal old, game
  end
end
