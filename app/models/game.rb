class Game < ApplicationRecord
  # Enums
  enum :state, {
    waiting_for_players: 0,
    placing_ships: 1,
    in_progress: 2,
    finished: 3
  }, validate: true

  # Associations
  belongs_to :player1, class_name: "Player"
  belongs_to :player2, class_name: "Player", optional: true
  belongs_to :current_turn_player, class_name: "Player", optional: true
  belongs_to :winner, class_name: "Player", optional: true

  has_many :boards, dependent: :destroy
  has_many :shots, dependent: :destroy

  # Validations
  validates :state, presence: true
  validate :players_must_be_different

  # Callbacks
  after_initialize :set_default_state, if: :new_record?

  # Scopes
  scope :active, -> { where(state: [ :placing_ships, :in_progress ]) }
  scope :waiting, -> { where(state: :waiting_for_players, player2_id: nil) }

  # Instance Methods
  def both_boards_ready?
    boards.count == 2 && boards.all?(&:ready)
  end

  def opponent_of(player)
    return nil unless player
    player_id = player.is_a?(Player) ? player.id : player
    return player2 if player1_id == player_id
    return player1 if player2_id == player_id
    nil
  end

  def board_for(player)
    player_id = player.is_a?(Player) ? player.id : player
    boards.find_by(player_id: player_id)
  end

  def my_turn?(player)
    player_id = player.is_a?(Player) ? player.id : player
    current_turn_player_id == player_id
  end

  def switch_turn!
    return unless in_progress?
    new_player = opponent_of(current_turn_player)
    update!(current_turn_player: new_player)
  end

  def check_winner!
    return unless in_progress?

    boards.each do |board|
      next unless board.all_ships_sunk?

      opponent = opponent_of(board.player)
      update!(state: :finished, winner: opponent)
      broadcast_game_over
      break
    end
  end

  def broadcast_game_over
    broadcast_replace_to "game_#{id}", partial: "games/game_over", locals: { game: self }
  end

  private

  def set_default_state
    self.state ||= :waiting_for_players
  end

  def players_must_be_different
    if player1_id.present? && player2_id.present? && player1_id == player2_id
      errors.add(:player2, "must be different from player1")
    end
  end
end
