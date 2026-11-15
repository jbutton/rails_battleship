require "application_system_test_case"

# Plays a whole game in two browsers, so every Turbo Stream broadcast between
# matchmaking and the victory screen has to reach the other player live.
class FullGameTest < ApplicationSystemTestCase
  include GameHelpers

  test "two players are matched, place fleets, and play to a finish" do
    using_session(:alice) do
      join_as "Alice"
      assert_text "Looking for an Opponent"
    end

    using_session(:bob) do
      join_as "Bob"
      assert_text "Place Your Ships"
      place_fleet
      assert_text "Waiting for opponent to place their ships"
    end

    using_session(:alice) do
      assert_text "Place Your Ships" # pushed to Alice when Bob joined
      place_fleet
      assert_text "Battle in Progress!"
      assert_text "Your Turn!"
    end

    using_session(:bob) { assert_text "Opponent's Turn" }

    targets = fleet_in_rows.flat_map { |ship| ship["coordinates"] }
    misses = (0...Board::GRID_SIZE).flat_map { |x| (5...Board::GRID_SIZE).map { |y| [ x, y ] } }

    targets.each_with_index do |cell, i|
      last_shot = i == targets.size - 1
      using_session(:alice) { fire_at cell["x"], cell["y"], expect: last_shot ? "Victory!" : "Opponent's Turn" }
      break if last_shot

      using_session(:bob) do
        assert_text "Your Turn!"
        fire_at(*misses[i])
      end
      using_session(:alice) { assert_text "Your Turn!" }
    end

    using_session(:bob) { assert_text "Defeat" }
  end

  private

  def join_as(name)
    visit root_path
    fill_in "Your Name", with: name
    click_on "Start Playing"
    click_on "Find Opponent"
    # Broadcasts sent before the stream is subscribed would be lost.
    assert_selector "turbo-cable-stream-source[connected]", visible: :all
  end

  def place_fleet
    Board::SHIPS.each_key.with_index { |_type, row| find(".ship-placement .cell[data-x='0'][data-y='#{row}']").click }
    click_on "Confirm Placement"
  end

  def fire_at(x, y, expect: "Opponent's Turn")
    find(".enemy-board .cell[data-x='#{x}'][data-y='#{y}']").click
    assert_text expect
  end
end
