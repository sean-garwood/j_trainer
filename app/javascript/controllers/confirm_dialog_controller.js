import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  show() {
    this.dialogTarget.classList.remove("hidden")
  }

  hide() {
    this.dialogTarget.classList.add("hidden")
  }

  // Close on Escape key
  keydown(event) {
    if (event.key === "Escape") this.hide()
  }
}
