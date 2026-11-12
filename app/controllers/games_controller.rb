class GamesController < ApplicationController
  before_action :require_player
  before_action :set_game, only: :show

  def index
    current_game = current_player.current_game
    @current_game = current_game unless current_game&.finished?
    @player = current_player
  end

  def show
    @player = current_player
  end

  def join
    game = GamePlay::MatchmakingService.new(current_player).call

    if game.placing_ships?
      redirect_to game_path(game), notice: "Match found! Place your ships."
    else
      redirect_to game_path(game), notice: "Searching for opponent..."
    end
  rescue ActiveRecord::ActiveRecordError => e
    redirect_to games_path, alert: "Error joining game: #{e.message}"
  end

  private

  def set_game
    @game = find_game_for_current_player(params[:id])
  end
end
