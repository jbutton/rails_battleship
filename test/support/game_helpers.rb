module GameHelpers
  # Ships laid out in rows 0-4, starting at column 0.
  def fleet_in_rows
    Board::SHIPS.each_with_index.map do |(type, length), row|
      { "type" => type.to_s, "coordinates" => (0...length).map { |x| { "x" => x, "y" => row } } }
    end
  end

  def start_matched_game(p1 = players(:alice), p2 = players(:bob))
    GamePlay::MatchmakingService.new(p1).call
    GamePlay::MatchmakingService.new(p2).call.reload
  end

  def start_battle(p1 = players(:alice), p2 = players(:bob))
    game = start_matched_game(p1, p2)
    game.boards.each { |board| board.place_ships(fleet_in_rows) }
    game.update!(state: :in_progress, current_turn_player: p1)
    game
  end

  def fire(game, shooter, x, y)
    GamePlay::FireShotService.new(game: game.reload, shooter: shooter, x: x, y: y).call
  end
end
