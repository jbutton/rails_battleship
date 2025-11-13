class ShotsController < ApplicationController
  before_action :require_player
  before_action :set_game

  def create
    result = GamePlay::FireShotService.new(
      game: @game,
      shooter: current_player,
      x: params[:x].to_i,
      y: params[:y].to_i
    ).call

    respond_to do |format|
      format.turbo_stream do
        if result[:success]
          render turbo_stream: [
            turbo_stream.replace(
              "game-board",
              partial: "games/board",
              locals: { game: @game, player: current_player }
            ),
            turbo_stream.prepend(
              "shots-log",
              partial: "shots/shot",
              locals: { shot: result[:shot] }
            )
          ]
        else
          render turbo_stream: turbo_stream.replace(
            "flash-messages",
            partial: "shared/flash",
            locals: { alert: result[:error] }
          ), status: :unprocessable_entity
        end
      end
      format.json do
        if result[:success]
          render json: { success: true, result: result[:result] }, status: :ok
        else
          render json: { success: false, error: result[:error] }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to games_path, alert: "Game not found"
  end

  def require_player
    unless current_player
      redirect_to new_player_path, alert: "Please enter your name first"
    end
  end
end
