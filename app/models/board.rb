class Board < ApplicationRecord
  # Constants
  GRID_SIZE = 10
  SHIPS = {
    carrier: 5,
    battleship: 4,
    cruiser: 3,
    submarine: 3,
    destroyer: 2
  }.freeze

  # Associations
  belongs_to :game
  belongs_to :player

  # Validations
  validates :game_id, uniqueness: { scope: :player_id }

  # Callbacks
  after_initialize :initialize_grid, if: :new_record?
  after_create :initialize_ships_json

  # Serialization
  serialize :grid_json, coder: JSON
  serialize :ships_json, coder: JSON

  # Instance Methods
  def grid
    @grid ||= JSON.parse(grid_json || "[]")
  end

  def ships
    @ships ||= JSON.parse(ships_json || "[]")
  end

  def place_ships(ships_data)
    return false unless valid_ships_placement?(ships_data)

    new_grid = initialize_empty_grid
    updated_ships = []

    ships_data.each do |ship_data|
      ship_type = ship_data["type"]
      coordinates = ship_data["coordinates"]

      coordinates.each do |coord|
        x, y = coord["x"], coord["y"]
        new_grid[y][x] = { "type" => ship_type, "hit" => false }
      end

      updated_ships << {
        "type" => ship_type,
        "coordinates" => coordinates,
        "sunk" => false
      }
    end

    self.grid_json = new_grid.to_json
    self.ships_json = updated_ships.to_json
    self.ready = true
    save
  end

  def process_shot(x, y)
    return :invalid if x < 0 || x >= GRID_SIZE || y < 0 || y >= GRID_SIZE

    current_grid = grid
    cell = current_grid[y][x]

    if cell.nil? || cell.empty?
      current_grid[y][x] = { "hit" => false, "shot" => true }
      self.grid_json = current_grid.to_json
      save
      return :miss
    end

    return :already_shot if cell["shot"] || cell["hit"]

    # Hit a ship
    cell["hit"] = true
    cell["shot"] = true
    current_grid[y][x] = cell
    self.grid_json = current_grid.to_json

    # Check if ship is sunk
    ship_type = cell["type"]
    if ship_sunk?(ship_type)
      mark_ship_as_sunk(ship_type)
      save
      return :sink
    end

    save
    :hit
  end

  def ship_sunk?(ship_type)
    current_grid = grid
    current_grid.flatten.none? do |cell|
      cell.is_a?(Hash) && cell["type"] == ship_type && !cell["hit"]
    end
  end

  def mark_ship_as_sunk(ship_type)
    current_ships = ships
    ship = current_ships.find { |s| s["type"] == ship_type }
    ship["sunk"] = true if ship
    self.ships_json = current_ships.to_json
  end

  def all_ships_sunk?
    ships.all? { |ship| ship["sunk"] }
  end

  def auto_place_ships!
    max_attempts = 100
    attempts = 0

    loop do
      attempts += 1
      break if attempts > max_attempts

      ships_data = generate_random_ships
      if place_ships(ships_data)
        return true
      end
    end

    false
  end

  def to_opponent_view
    current_grid = grid
    current_grid.map do |row|
      row.map do |cell|
        if cell.is_a?(Hash) && (cell["hit"] || cell["shot"])
          { "hit" => cell["hit"], "shot" => true }
        else
          {}
        end
      end
    end
  end

  private

  def initialize_grid
    self.grid_json ||= initialize_empty_grid.to_json
  end

  def initialize_ships_json
    self.ships_json ||= [].to_json
  end

  def initialize_empty_grid
    Array.new(GRID_SIZE) { Array.new(GRID_SIZE) { {} } }
  end

  def valid_ships_placement?(ships_data)
    return false if ships_data.length != SHIPS.length

    ships_by_type = ships_data.group_by { |s| s["type"] }
    return false unless SHIPS.keys.all? { |type| ships_by_type.key?(type.to_s) }

    occupied_cells = Set.new

    ships_data.each do |ship_data|
      ship_type = ship_data["type"]
      expected_length = SHIPS[ship_type.to_sym]
      coordinates = ship_data["coordinates"]

      return false if coordinates.length != expected_length
      return false unless valid_ship_coordinates?(coordinates, occupied_cells)

      coordinates.each { |coord| occupied_cells.add([ coord["x"], coord["y"] ]) }
    end

    true
  end

  def valid_ship_coordinates?(coordinates, occupied_cells)
    return false if coordinates.empty?

    coordinates.each do |coord|
      x, y = coord["x"], coord["y"]
      return false if x < 0 || x >= GRID_SIZE || y < 0 || y >= GRID_SIZE
      return false if occupied_cells.include?([ x, y ])
    end

    # Check if coordinates form a straight line
    xs = coordinates.map { |c| c["x"] }
    ys = coordinates.map { |c| c["y"] }

    horizontal = xs.uniq.length == xs.length && ys.uniq.length == 1
    vertical = ys.uniq.length == ys.length && xs.uniq.length == 1

    return false unless horizontal || vertical

    # Check if coordinates are contiguous
    if horizontal
      xs.sort!
      xs.each_cons(2).all? { |a, b| b == a + 1 }
    else
      ys.sort!
      ys.each_cons(2).all? { |a, b| b == a + 1 }
    end
  end

  def generate_random_ships
    ships_data = []
    occupied_cells = Set.new

    SHIPS.each do |ship_type, length|
      max_attempts = 100
      attempts = 0

      loop do
        attempts += 1
        break if attempts > max_attempts

        horizontal = rand(2) == 0
        if horizontal
          x = rand(GRID_SIZE - length + 1)
          y = rand(GRID_SIZE)
          coordinates = (0...length).map { |i| { "x" => x + i, "y" => y } }
        else
          x = rand(GRID_SIZE)
          y = rand(GRID_SIZE - length + 1)
          coordinates = (0...length).map { |i| { "x" => x, "y" => y + i } }
        end

        if coordinates.none? { |coord| occupied_cells.include?([ coord["x"], coord["y"] ]) }
          coordinates.each { |coord| occupied_cells.add([ coord["x"], coord["y"] ]) }
          ships_data << { "type" => ship_type.to_s, "coordinates" => coordinates }
          break
        end
      end
    end

    ships_data
  end
end
