import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["grid", "shipInfo", "shipStatus", "submitButton", "orientationLabel"]
  static values = { boardId: Number }

  connect() {
    this.placedShips = []
    this.currentShipIndex = 0
    this.currentOrientation = "horizontal"
    this.gridSize = 10
    this.ships = this.getShipsConfig()
    this.updateCurrentShip()
    this.handleKeydown = (event) => {
      if (event.key === "r" || event.key === "R") this.rotate()
    }
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  rotate() {
    this.currentOrientation = this.currentOrientation === "horizontal" ? "vertical" : "horizontal"
    if (this.hasOrientationLabelTarget) {
      this.orientationLabelTarget.textContent = this.currentOrientation === "horizontal" ? "Horizontal" : "Vertical"
    }
    if (this.lastHoveredCell) this.cellHover({ currentTarget: this.lastHoveredCell })
  }

  getShipsConfig() {
    return Array.from(this.shipInfoTargets).map(target => ({
      type: target.dataset.type,
      length: parseInt(target.dataset.length),
      placed: false,
      element: target
    }))
  }

  cellClick(event) {
    const cell = event.currentTarget
    const x = parseInt(cell.dataset.x)
    const y = parseInt(cell.dataset.y)

    if (this.currentShipIndex < this.ships.length) {
      const ship = this.ships[this.currentShipIndex]
      if (this.canPlaceShip(x, y, ship.length, this.currentOrientation)) {
        this.placeShip(x, y, ship)
      }
    }
  }

  cellHover(event) {
    // Clear previous hover highlights
    this.gridTarget.querySelectorAll('.cell').forEach(c => c.classList.remove('hover-valid', 'hover-invalid'))

    if (this.currentShipIndex >= this.ships.length) return

    const cell = event.currentTarget
    this.lastHoveredCell = cell
    const x = parseInt(cell.dataset.x)
    const y = parseInt(cell.dataset.y)
    const ship = this.ships[this.currentShipIndex]

    const canPlace = this.canPlaceShip(x, y, ship.length, this.currentOrientation)
    const cells = this.getShipCells(x, y, ship.length, this.currentOrientation)

    cells.forEach(([cx, cy]) => {
      const targetCell = this.getCellAt(cx, cy)
      if (targetCell) {
        targetCell.classList.add(canPlace ? 'hover-valid' : 'hover-invalid')
      }
    })
  }

  canPlaceShip(x, y, length, orientation) {
    const cells = this.getShipCells(x, y, length, orientation)

    // Check bounds and collisions
    for (const [cx, cy] of cells) {
      if (cx < 0 || cx >= this.gridSize || cy < 0 || cy >= this.gridSize) {
        return false
      }
      const cell = this.getCellAt(cx, cy)
      if (cell && cell.classList.contains('ship-placed')) {
        return false
      }
    }
    return true
  }

  getShipCells(x, y, length, orientation) {
    const cells = []
    for (let i = 0; i < length; i++) {
      if (orientation === "horizontal") {
        cells.push([x + i, y])
      } else {
        cells.push([x, y + i])
      }
    }
    return cells
  }

  placeShip(x, y, ship) {
    const cells = this.getShipCells(x, y, ship.length, this.currentOrientation)
    const coordinates = cells.map(([cx, cy]) => ({ x: cx, y: cy }))

    // Mark cells as occupied
    cells.forEach(([cx, cy]) => {
      const cell = this.getCellAt(cx, cy)
      if (cell) {
        cell.classList.add('ship-placed', ship.type)
      }
    })

    // Record placement
    this.placedShips.push({
      type: ship.type,
      coordinates: coordinates
    })

    // Update ship status
    ship.placed = true
    this.shipStatusTargets[this.currentShipIndex].textContent = '✅'

    // Move to next ship
    this.currentShipIndex++
    this.updateCurrentShip()

    // Refresh the hover preview for the next ship
    this.gridTarget.querySelectorAll('.cell').forEach(c => c.classList.remove('hover-valid', 'hover-invalid'))

    // Check if all ships placed
    if (this.currentShipIndex >= this.ships.length) {
      this.submitButtonTarget.disabled = false
    }
  }

  updateCurrentShip() {
    this.shipInfoTargets.forEach((target, index) => {
      if (index === this.currentShipIndex) {
        target.classList.add('current')
      } else {
        target.classList.remove('current')
      }
    })
  }

  getCellAt(x, y) {
    return this.gridTarget.querySelector(`[data-x="${x}"][data-y="${y}"]`)
  }

  reset() {
    this.placedShips = []
    this.currentShipIndex = 0
    this.gridTarget.querySelectorAll('.cell').forEach(cell => {
      cell.className = 'cell'
    })
    this.ships.forEach((ship, index) => {
      ship.placed = false
      this.shipStatusTargets[index].textContent = '⬜'
    })
    this.submitButtonTarget.disabled = true
    this.updateCurrentShip()
  }

  async submitPlacement() {
    if (this.placedShips.length !== this.ships.length) {
      alert('Please place all ships first!')
      return
    }

    this.submitButtonTarget.disabled = true

    try {
      const response = await fetch(`/boards/${this.boardIdValue}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          ships_data: JSON.stringify(this.placedShips)
        })
      })

      // The server answers with a Turbo Stream: the next screen, or a flash message on error
      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      console.error('Error placing ships:', error)
      alert('Failed to place ships. Please try again.')
    } finally {
      if (this.element.isConnected) this.submitButtonTarget.disabled = false
    }
  }
}
