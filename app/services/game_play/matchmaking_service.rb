module GamePlay
  class MatchmakingService
    PLACEMENT_TIME_LIMIT = 120.seconds

    def initialize(player)
      @player = player
    end

    def call
      ActiveRecord::Base.transaction do
        game = find_or_create_game

        if game.player2.present?
          # Game is full, start ship placement phase
          start_ship_placement_phase(game)
        end

        game
      end
    end

    private

    attr_reader :player

    def find_or_create_game
      # Try to find a waiting game
      waiting_game = Game.waiting.lock.first

      if waiting_game
        # Join as player 2
        waiting_game.update!(player2: player)
        player.update!(status: :in_game, current_game: waiting_game)
        waiting_game
      else
        # Create new game
        game = Game.create!(
          player1: player,
          state: :waiting_for_players
        )
        player.update!(status: :searching, current_game: game)
        game
      end
    end

    def start_ship_placement_phase(game)
      deadline = PLACEMENT_TIME_LIMIT.from_now

      game.update!(
        state: :placing_ships,
        ships_placement_deadline: deadline
      )

      # Update player1's status to in_game
      game.player1.update!(status: :in_game)

      # Create boards for both players
      game.boards.find_or_create_by!(player: game.player1)
      game.boards.find_or_create_by!(player: game.player2)

      # Schedule auto-placement job
      AutoPlaceShipsJob.set(wait_until: deadline).perform_later(game.id)

      # Broadcast to both players
      broadcast_placement_phase_started(game)
    end

    def broadcast_placement_phase_started(game)
      [ game.player1, game.player2 ].each do |player|
        Turbo::StreamsChannel.broadcast_replace_to(
          "player_#{player.id}",
          target: "game-container",
          partial: "games/place_ships",
          locals: { game: game, player: player }
        )
      end
    end
  end
end
