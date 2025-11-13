class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.integer :game_id, null: false
      t.integer :player_id, null: false
      t.text :grid_json
      t.text :ships_json
      t.boolean :ready, default: false, null: false

      t.timestamps
    end

    add_index :boards, :game_id
    add_index :boards, :player_id
    add_index :boards, [ :game_id, :player_id ], unique: true
  end
end
