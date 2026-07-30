import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "consent", "submit", "error", "label"]
  static values = { maxMb: Number }

  static ALLOWED_TYPES = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ]

  browse(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("has-file")
  }

  dragleave() {
    this.dropzoneTarget.classList.remove("has-file")
  }

  drop(event) {
    event.preventDefault()
    if (event.dataTransfer.files.length > 0) {
      this.inputTarget.files = event.dataTransfer.files
      this.fileChanged()
    }
  }

  fileChanged() {
    const file = this.inputTarget.files[0]
    this.clearError()
    if (!file) return this.toggleSubmit()

    if (!this.constructor.ALLOWED_TYPES.includes(file.type)) {
      this.showError("Unsupported file type. Please upload a PDF, DOC or DOCX file.")
    } else if (file.size > this.maxMbValue * 1024 * 1024) {
      this.showError(`File is too large. The maximum size is ${this.maxMbValue} MB.`)
    } else {
      this.dropzoneTarget.classList.add("has-file")
      this.labelTarget.textContent = file.name
      sessionStorage.removeItem("cvPollAttempts")
    }
    this.toggleSubmit()
  }

  toggleSubmit() {
    const file = this.inputTarget.files[0]
    const validFile = file && !this.errorVisible
    this.submitTarget.disabled = !(validFile && this.consentTarget.checked)
  }

  showError(message) {
    this.errorVisible = true
    this.errorTarget.textContent = message
    this.errorTarget.style.display = "block"
    this.inputTarget.value = ""
    this.dropzoneTarget.classList.remove("has-file")
  }

  clearError() {
    this.errorVisible = false
    this.errorTarget.textContent = ""
    this.errorTarget.style.display = "none"
  }
}
