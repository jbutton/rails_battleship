class AutoPlaceShipsJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.placing_ships?

    # Auto-place ships for any board that's not ready
    game.boards.where(ready: false).each do |board|
      board.auto_place_ships!
    end

    game.start_battle! if game.both_boards_ready?
  end
end
