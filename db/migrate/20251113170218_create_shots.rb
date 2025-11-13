class CreateShots < ActiveRecord::Migration[8.1]
  def change
    create_table :shots do |t|
      t.integer :game_id, null: false
      t.integer :shooter_id, null: false
      t.integer :target_player_id, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.integer :result, null: false

      t.timestamps
    end

    add_index :shots, :game_id
    add_index :shots, :shooter_id
    add_index :shots, :target_player_id
    add_index :shots, [ :game_id, :target_player_id, :x, :y ], unique: true, name: "index_shots_uniqueness"
  end
end
