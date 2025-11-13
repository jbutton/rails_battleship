class Shot < ApplicationRecord
  # Enums
  enum :result, { miss: 0, hit: 1, sink: 2 }, validate: true

  # Associations
  belongs_to :game
  belongs_to :shooter, class_name: "Player"
  belongs_to :target_player, class_name: "Player"

  # Validations
  validates :x, :y, presence: true
  validates :x, :y, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: Board::GRID_SIZE }
  validates :x, uniqueness: { scope: [ :game_id, :target_player_id, :y ] }

  # Callbacks
  after_create :broadcast_shot

  # Scopes
  scope :for_game, ->(game_id) { where(game_id: game_id) }
  scope :hits, -> { where(result: [ :hit, :sink ]) }
  scope :misses, -> { where(result: :miss) }

  private

  def broadcast_shot
    broadcast_prepend_to "game_#{game_id}_log",
                         partial: "shots/shot",
                         locals: { shot: self },
                         target: "shots-log"
  end
end
