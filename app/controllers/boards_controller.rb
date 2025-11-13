class BoardsController < ApplicationController
  before_action :require_player
  before_action :set_board

  def update
    ships_data = JSON.parse(params[:ships_data])

    result = GamePlay::ShipPlacementService.new(
      board: @board,
      ships_data: ships_data
    ).call

    respond_to do |format|
      format.turbo_stream do
        if result[:success]
          # Reload game to get latest state
          game = @board.game.reload

          # If game has started, show play screen. Otherwise show waiting screen
          if game.in_progress?
            render turbo_stream: turbo_stream.replace(
              "game-container",
              partial: "games/play",
              locals: { game: game, player: current_player }
            )
          else
            render turbo_stream: turbo_stream.replace(
              "game-container",
              partial: "games/waiting_for_opponent",
              locals: { game: game, player: current_player }
            )
          end
        else
          # Even if placement failed, check if the game has started (e.g., due to auto-placement)
          game = @board.game.reload

          if game.in_progress?
            # Game has started, show play screen instead of error
            render turbo_stream: [
              turbo_stream.replace(
                "game-container",
                partial: "games/play",
                locals: { game: game, player: current_player }
              ),
              turbo_stream.replace(
                "flash-messages",
                partial: "shared/flash",
                locals: { notice: "Ships were placed automatically. Game has started!" }
              )
            ]
          else
            # Show error message
            render turbo_stream: turbo_stream.replace(
              "flash-messages",
              partial: "shared/flash",
              locals: { alert: result[:error] }
            )
          end
        end
      end
      format.json do
        if result[:success]
          render json: { success: true }, status: :ok
        else
          render json: { success: false, error: result[:error] }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_board
    @board = Board.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to games_path, alert: "Board not found"
  end

  def require_player
    unless current_player
      redirect_to new_player_path, alert: "Please enter your name first"
    end
  end
end
