import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["jobFunction", "group"]

  connect() {
    this.filter()
  }

  filter() {
    const key = this.jobFunctionTarget.selectedOptions[0]?.dataset.key
    this.groupTargets.forEach((group) => {
      group.hidden = Boolean(key) && group.dataset.jobFunctionKey !== key
    })
  }
}
