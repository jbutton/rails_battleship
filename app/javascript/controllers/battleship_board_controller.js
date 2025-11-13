import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    gameId: Number,
    canFire: Boolean
  }

  connect() {
    console.log("Battleship board connected", this.gameIdValue, this.canFireValue)
  }

  async fire(event) {
    if (!this.canFireValue) {
      return
    }

    const cell = event.currentTarget
    const x = parseInt(cell.dataset.x)
    const y = parseInt(cell.dataset.y)

    // Disable cell immediately to prevent double-clicks
    cell.style.pointerEvents = 'none'

    try {
      const response = await fetch(`/games/${this.gameIdValue}/shots`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ x, y })
      })

      const data = await response.json()

      if (!response.ok) {
        alert(data.error || 'Failed to fire shot')
        cell.style.pointerEvents = 'auto'
      }
    } catch (error) {
      console.error('Error firing shot:', error)
      alert('Failed to fire shot. Please try again.')
      cell.style.pointerEvents = 'auto'
    }
  }
}
