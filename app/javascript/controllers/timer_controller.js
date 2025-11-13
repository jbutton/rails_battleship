import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { deadline: String }

  connect() {
    this.updateTimer()
    this.intervalId = setInterval(() => this.updateTimer(), 1000)
  }

  disconnect() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
    }
  }

  updateTimer() {
    const now = new Date().getTime()
    const deadline = new Date(this.deadlineValue).getTime()
    const remaining = deadline - now

    if (remaining <= 0) {
      this.displayTarget.textContent = "00:00"
      if (this.intervalId) {
        clearInterval(this.intervalId)
      }
      return
    }

    const minutes = Math.floor(remaining / 60000)
    const seconds = Math.floor((remaining % 60000) / 1000)

    this.displayTarget.textContent = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
  }
}
