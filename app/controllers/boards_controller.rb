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
          render turbo_stream: turbo_stream.replace(
            "game-container",
            partial: "games/waiting_for_opponent",
            locals: { game: @board.game, player: current_player }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "flash-messages",
            partial: "shared/flash",
            locals: { alert: result[:error] }
          )
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
