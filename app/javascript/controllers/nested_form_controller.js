import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now())
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")
    const destroy = row.querySelector("input[name*='_destroy']")
    if (destroy) {
      destroy.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }

  toggleCurrent(event) {
    const row = event.target.closest("[data-nested-form-row]")
    const end = row.querySelector("[data-role='end-date']")
    end.disabled = event.target.checked
    if (event.target.checked) end.value = ""
  }
}
