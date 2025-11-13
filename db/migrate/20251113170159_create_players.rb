class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.integer :current_game_id

      t.timestamps
    end

    add_index :players, :status
    add_index :players, :current_game_id
  end
end
