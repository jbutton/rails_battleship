class AutoPlaceShipsJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.placing_ships?

    # Auto-place ships for any board that's not ready
    game.boards.where(ready: false).each do |board|
      board.auto_place_ships!
    end

    # If both boards are ready now, start the game
    if game.both_boards_ready?
      game.update!(
        state: :in_progress,
        current_turn_player: game.player1
      )

      # Broadcast game started
      broadcast_game_started(game)
    end
  end

  private

  def broadcast_game_started(game)
    [ game.player1, game.player2 ].each do |player|
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_#{player.id}",
        target: "game-container",
        partial: "games/play",
        locals: { game: game, player: player }
      )
    end
  end
end
