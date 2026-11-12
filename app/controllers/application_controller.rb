class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_player

  private

  def current_player
    return nil unless session[:player_id]

    @current_player ||= Player.find_by(id: session[:player_id])
  end

  def require_player
    redirect_to new_player_path, alert: "Please enter your name first" unless current_player
  end

  def find_game_for_current_player(id)
    game = Game.find_by(id: id)
    return game if game && [ game.player1_id, game.player2_id ].include?(current_player.id)

    redirect_to games_path, alert: "Game not found"
    nil
  end
end
