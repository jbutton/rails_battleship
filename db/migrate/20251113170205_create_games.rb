class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.integer :state, default: 0, null: false
      t.integer :player1_id, null: false
      t.integer :player2_id
      t.integer :current_turn_player_id
      t.integer :winner_id
      t.datetime :ships_placement_deadline

      t.timestamps
    end

    add_index :games, :state
    add_index :games, :player1_id
    add_index :games, :player2_id
    add_index :games, :current_turn_player_id
    add_index :games, :winner_id
  end
end
