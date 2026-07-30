import { Controller } from "@hotwired/stimulus"

// a fresh instance connects on every frame reload, so all logic lives in connect()
const MAX_ATTEMPTS = 100

export default class extends Controller {
  static values = { status: String, redirectUrl: String, fallbackUrl: String }

  connect() {
    if (this.statusValue === "completed") {
      sessionStorage.removeItem("cvPollAttempts")
      window.location = this.redirectUrlValue
      return
    }
    if (this.statusValue === "failed") {
      sessionStorage.removeItem("cvPollAttempts")
      return
    }

    const attempts = Number(sessionStorage.getItem("cvPollAttempts") || 0) + 1
    sessionStorage.setItem("cvPollAttempts", attempts)
    if (attempts > MAX_ATTEMPTS) {
      this.showFallback()
      return
    }

    this.timer = setTimeout(() => this.element.closest("turbo-frame")?.reload(), 2000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  showFallback() {
    this.element.innerHTML = `
      <h2>This is taking longer than expected</h2>
      <p>You can keep waiting, or continue and fill in your profile manually.</p>
      <p style="margin-top:16px;"><a class="btn btn-primary" data-turbo-frame="_top" href="${this.fallbackUrlValue}">Continue manually</a></p>
    `
  }
}
