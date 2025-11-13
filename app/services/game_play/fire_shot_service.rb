module GamePlay
  class FireShotService
    class InvalidShotError < StandardError; end
    class NotYourTurnError < StandardError; end
    class GameNotInProgressError < StandardError; end

    def initialize(game:, shooter:, x:, y:)
      @game = game
      @shooter = shooter
      @x = x
      @y = y
      @errors = []
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        process_shot
      end

      { success: true, shot: @shot, result: @result }
    rescue InvalidShotError, NotYourTurnError, GameNotInProgressError => e
      { success: false, error: e.message }
    end

    private

    attr_reader :game, :shooter, :x, :y, :errors

    def validate!
      raise GameNotInProgressError, "Game is not in progress" unless game.in_progress?
      raise NotYourTurnError, "It's not your turn" unless game.my_turn?(shooter)

      opponent = game.opponent_of(shooter)
      raise InvalidShotError, "Opponent not found" unless opponent

      @target_board = game.board_for(opponent)
      raise InvalidShotError, "Target board not found" unless @target_board

      # Check if already shot at this position
      existing_shot = game.shots.find_by(target_player: opponent, x: x, y: y)
      raise InvalidShotError, "Already shot at this position" if existing_shot
    end

    def process_shot
      # Process the shot on the board
      @result = @target_board.process_shot(x, y)

      case @result
      when :invalid
        raise InvalidShotError, "Invalid coordinates"
      when :already_shot
        raise InvalidShotError, "Already shot at this position"
      end

      # Create shot record
      opponent = game.opponent_of(shooter)
      @shot = game.shots.create!(
        shooter: shooter,
        target_player: opponent,
        x: x,
        y: y,
        result: @result
      )

      # Check for winner
      game.check_winner!

      # Switch turn if game is still in progress
      game.switch_turn! if game.in_progress?

      # Broadcast updates
      broadcast_shot_result
    end

    def broadcast_shot_result
      # Broadcast to both players
      [ game.player1, game.player2 ].each do |player|
        Turbo::StreamsChannel.broadcast_replace_to(
          "player_#{player.id}_game_#{game.id}",
          target: "game-board",
          partial: "games/board",
          locals: { game: game, player: player }
        )
      end
    end
  end
end
