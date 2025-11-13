module GamePlay
  class ShipPlacementService
    class InvalidPlacementError < StandardError; end

    def initialize(board:, ships_data:)
      @board = board
      @ships_data = ships_data
      @game = board.game
    end

    def call
      validate_game_state!

      ActiveRecord::Base.transaction do
        place_ships
        check_if_both_ready
      end

      { success: true, board: @board }
    rescue InvalidPlacementError => e
      { success: false, error: e.message }
    end

    private

    attr_reader :board, :ships_data, :game

    def validate_game_state!
      unless game.placing_ships?
        if game.in_progress?
          raise InvalidPlacementError, "The game has already started. Ships have been placed automatically."
        else
          raise InvalidPlacementError, "Cannot place ships at this time. Game state: #{game.state}"
        end
      end

      raise InvalidPlacementError, "Your ships have already been placed" if board.ready?

      if game.ships_placement_deadline && Time.current > game.ships_placement_deadline
        raise InvalidPlacementError, "Placement time has expired. Ships will be placed automatically."
      end
    end

    def place_ships
      unless board.place_ships(ships_data)
        raise InvalidPlacementError, "Invalid ship placement"
      end
    end

    def check_if_both_ready
      return unless game.both_boards_ready?

      # Both players are ready, start the game
      game.update!(
        state: :in_progress,
        current_turn_player: game.player1
      )

      broadcast_game_started
    end

    def broadcast_game_started
      # Broadcast to both players on both their channels
      [ game.player1, game.player2 ].each do |player|
        # Broadcast to player channel
        Turbo::StreamsChannel.broadcast_replace_to(
          "player_#{player.id}",
          target: "game-container",
          partial: "games/play",
          locals: { game: game, player: player }
        )

        # Also broadcast to player_game channel for reliability
        Turbo::StreamsChannel.broadcast_replace_to(
          "player_#{player.id}_game_#{game.id}",
          target: "game-container",
          partial: "games/play",
          locals: { game: game, player: player }
        )
      end
    end
  end
end
