require "test_helper"

class BoardTest < ActiveSupport::TestCase
  include GameHelpers

  setup do
    @board = start_matched_game.board_for(players(:alice))
  end

  test "starts with an empty 10x10 grid" do
    assert_equal Board::GRID_SIZE, @board.grid.size
    assert @board.grid.flatten.all?(&:empty?)
  end

  test "accepts a valid fleet and marks the board ready" do
    assert @board.place_ships(fleet_in_rows)
    assert @board.reload.ready?
  end

  test "rejects a fleet with a missing ship" do
    assert_not @board.place_ships(fleet_in_rows.first(4))
  end

  test "rejects overlapping ships" do
    fleet = fleet_in_rows
    fleet[1]["coordinates"] = (0...4).map { |x| { "x" => x, "y" => 0 } }
    assert_not @board.place_ships(fleet)
  end

  test "rejects ships that leave the grid" do
    fleet = fleet_in_rows
    fleet[0]["coordinates"] = (7...12).map { |x| { "x" => x, "y" => 0 } }
    assert_not @board.place_ships(fleet)
  end

  test "rejects diagonal or gapped ships" do
    fleet = fleet_in_rows
    fleet[4]["coordinates"] = [ { "x" => 0, "y" => 4 }, { "x" => 2, "y" => 4 } ]
    assert_not @board.place_ships(fleet)
  end

  test "accepts vertical ships" do
    fleet = Board::SHIPS.each_with_index.map do |(type, length), col|
      { "type" => type.to_s, "coordinates" => (0...length).map { |y| { "x" => col, "y" => y } } }
    end
    assert @board.place_ships(fleet)
  end

  test "process_shot reports miss, hit, sink and repeats" do
    @board.place_ships(fleet_in_rows)

    assert_equal :miss, @board.process_shot(9, 9)
    assert_equal :hit, @board.process_shot(0, 4)
    assert_equal :already_shot, @board.process_shot(0, 4)
    assert_equal :sink, @board.process_shot(1, 4)
    assert_equal :invalid, @board.process_shot(10, 0)
  end

  test "all_ships_sunk? once every ship cell is hit" do
    @board.place_ships(fleet_in_rows)
    cells = fleet_in_rows.flat_map { |s| s["coordinates"] }

    cells[0..-2].each { |c| @board.process_shot(c["x"], c["y"]) }
    assert_not @board.all_ships_sunk?

    @board.process_shot(cells.last["x"], cells.last["y"])
    assert @board.all_ships_sunk?
  end

  test "opponent view only reveals shots, never ship positions" do
    @board.place_ships(fleet_in_rows)
    @board.process_shot(0, 0)
    @board.process_shot(9, 9)

    view = @board.to_opponent_view.flatten
    assert view.none? { |cell| cell.key?("type") }
    assert_equal 2, view.count { |cell| cell["shot"] }
  end

  test "auto_place_ships! produces a legal fleet" do
    assert @board.auto_place_ships!
    assert_equal Board::SHIPS.values.sum, @board.grid.flatten.count { |c| c["type"] }
  end
end
