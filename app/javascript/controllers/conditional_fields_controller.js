import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "jobFunction", "employmentTypes", "bigStatusSelect",
    "salary", "percentage", "big", "bigNumber", "dailyRevenue"
  ]

  connect() {
    this.refresh()
  }

  refresh() {
    const fn = this.selectedJobFunction()
    const checked = Array.from(this.employmentTypesTarget.querySelectorAll("input:checked"))
    const salaryBased = checked.some((el) => el.dataset.salaryBased === "true")
    const percentageBased = checked.some((el) => el.dataset.percentageBased === "true")
    const bigStatus = this.bigStatusSelectTarget.value

    this.toggle(this.salaryTarget, salaryBased)
    this.toggle(this.percentageTarget, percentageBased)
    this.toggle(this.bigTarget, fn.requiresBig)
    this.toggle(this.bigNumberTarget, fn.requiresBig && bigStatus === "registered")
    this.toggle(this.dailyRevenueTarget, fn.requiresDailyRevenue)
  }

  selectedJobFunction() {
    const option = this.jobFunctionTarget.selectedOptions[0]
    return {
      requiresBig: option?.dataset.requiresBig === "true",
      requiresDailyRevenue: option?.dataset.requiresDailyRevenue === "true"
    }
  }

  toggle(element, show) {
    element.hidden = !show
  }
}
