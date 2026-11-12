class BoardsController < ApplicationController
  before_action :require_player
  before_action :set_board

  def update
    result = GamePlay::ShipPlacementService.new(
      board: @board,
      ships_data: JSON.parse(params.require(:ships_data))
    ).call
    game = @board.game.reload

    respond_to do |format|
      format.turbo_stream do
        if result[:success] || game.in_progress?
          streams = [ turbo_stream.replace("game-container", partial: screen_for(game), locals: { game: game, player: current_player }) ]
          unless result[:success]
            streams << turbo_stream.update("flash-messages", partial: "shared/flash",
                                            locals: { notice: "Ships were placed automatically. Game has started!" })
          end
          render turbo_stream: streams
        else
          render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash", locals: { alert: result[:error] })
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
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def set_board
    @board = current_player.boards.find_by(id: params[:id])
    redirect_to games_path, alert: "Board not found" unless @board
  end

  def screen_for(game)
    game.in_progress? ? "games/play" : "games/waiting_for_opponent"
  end
end
