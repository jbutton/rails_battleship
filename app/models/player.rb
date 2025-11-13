class Player < ApplicationRecord
  # Enums
  enum :status, { idle: 0, searching: 1, in_game: 2 }, validate: true

  # Associations
  belongs_to :current_game, class_name: "Game", optional: true
  has_many :games_as_player1, class_name: "Game", foreign_key: :player1_id, dependent: :nullify
  has_many :games_as_player2, class_name: "Game", foreign_key: :player2_id, dependent: :nullify
  has_many :boards, dependent: :destroy
  has_many :shots_fired, class_name: "Shot", foreign_key: :shooter_id, dependent: :destroy
  has_many :shots_received, class_name: "Shot", foreign_key: :target_player_id, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }

  # Callbacks
  after_initialize :set_default_status, if: :new_record?

  # Scopes
  scope :searching, -> { where(status: :searching) }
  scope :in_game, -> { where(status: :in_game) }

  # Instance Methods
  def games
    Game.where("player1_id = ? OR player2_id = ?", id, id)
  end

  def opponent_in(game)
    return nil unless game
    game.player1_id == id ? game.player2 : game.player1
  end

  private

  def set_default_status
    self.status ||= :idle
  end
end
