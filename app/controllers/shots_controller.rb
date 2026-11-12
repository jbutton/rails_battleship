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

    if result[:success]
      render json: { success: true, result: result[:result] }, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = find_game_for_current_player(params[:game_id])
  end
end
