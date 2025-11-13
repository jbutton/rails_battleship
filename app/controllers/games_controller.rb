class GamesController < ApplicationController
  before_action :require_player
  before_action :set_game, only: [ :show, :fire ]

  def index
    @current_game = current_player.current_game
    @player = current_player
  end

  def show
    @player = current_player
    @my_board = @game.board_for(@player)
    @opponent = @game.opponent_of(@player)
    @opponent_board = @game.board_for(@opponent) if @opponent
  end

  def join
    game = GamePlay::MatchmakingService.new(current_player).call

    if game.placing_ships?
      redirect_to game_path(game), notice: "Match found! Place your ships."
    else
      redirect_to game_path(game), notice: "Searching for opponent..."
    end
  rescue => e
    redirect_to games_path, alert: "Error joining game: #{e.message}"
  end

  def fire
    result = GamePlay::FireShotService.new(
      game: @game,
      shooter: current_player,
      x: params[:x].to_i,
      y: params[:y].to_i
    ).call

    respond_to do |format|
      format.turbo_stream do
        if result[:success]
          render turbo_stream: turbo_stream.replace(
            "game-container",
            partial: "games/play",
            locals: { game: @game, player: current_player }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "flash-messages",
            partial: "shared/flash",
            locals: { alert: result[:error] }
          )
        end
      end
      format.html do
        if result[:success]
          redirect_to game_path(@game), notice: "Shot fired!"
        else
          redirect_to game_path(@game), alert: result[:error]
        end
      end
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to games_path, alert: "Game not found"
  end

  def require_player
    unless current_player
      redirect_to new_player_path, alert: "Please enter your name first"
    end
  end
end
