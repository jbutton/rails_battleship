# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_13_170218) do
  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.text "grid_json"
    t.integer "player_id", null: false
    t.boolean "ready", default: false, null: false
    t.text "ships_json"
    t.datetime "updated_at", null: false
    t.index ["game_id", "player_id"], name: "index_boards_on_game_id_and_player_id", unique: true
    t.index ["game_id"], name: "index_boards_on_game_id"
    t.index ["player_id"], name: "index_boards_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_turn_player_id"
    t.integer "player1_id", null: false
    t.integer "player2_id"
    t.datetime "ships_placement_deadline"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["current_turn_player_id"], name: "index_games_on_current_turn_player_id"
    t.index ["player1_id"], name: "index_games_on_player1_id"
    t.index ["player2_id"], name: "index_games_on_player2_id"
    t.index ["state"], name: "index_games_on_state"
    t.index ["winner_id"], name: "index_games_on_winner_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_game_id"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["current_game_id"], name: "index_players_on_current_game_id"
    t.index ["status"], name: "index_players_on_status"
  end

  create_table "shots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "result", null: false
    t.integer "shooter_id", null: false
    t.integer "target_player_id", null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.index ["game_id", "target_player_id", "x", "y"], name: "index_shots_uniqueness", unique: true
    t.index ["game_id"], name: "index_shots_on_game_id"
    t.index ["shooter_id"], name: "index_shots_on_shooter_id"
    t.index ["target_player_id"], name: "index_shots_on_target_player_id"
  end
end
