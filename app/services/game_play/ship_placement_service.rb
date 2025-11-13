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
      raise InvalidPlacementError, "Game must be in placing_ships state" unless game.placing_ships?
      raise InvalidPlacementError, "Board already has ships placed" if board.ready?
      raise InvalidPlacementError, "Placement deadline has passed" if game.ships_placement_deadline && Time.current > game.ships_placement_deadline
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
end
