import { Controller } from "@hotwired/stimulus";
import { MAX_RESPONSE_TIME, MAX_BUZZ_TIME } from "../constants";

export default class extends Controller {
  static targets = ["timeField", "input", "countdown"];
  static values = {
    maxResponseTime: { type: Number, default: MAX_RESPONSE_TIME },
    maxBuzzTime: { type: Number, default: MAX_BUZZ_TIME },
  };

  get now() {
    return new Date().getTime(); // FIX: Added return
  }

  connect() {
    this.clueDisplayTime = this.now;
    this.responseTime = null;
    this.maxBuzzTime = this.maxBuzzTimeValue;
    this.maxResponseTime = this.maxResponseTimeValue;
    this.startResponseCountdown();
  }

  startResponseCountdown() {
    this.timeLeft = this.maxResponseTime; // FIX: Define in scope
    this.updateCountdown();

    this.responseInterval = setInterval(() => {
      this.timeLeft -= 0.1;
      this.updateCountdown();

      if (this.timeLeft <= 0) {
        clearInterval(this.responseInterval);
        this.countdownTarget.textContent = "Time's up!";
        this.inputTarget.disabled = true;
        this.timeFieldTarget.value = this.maxResponseTime;
        this.element.requestSubmit(); // Auto-submit when timer expires
      }
    }, 100); // Update every 100ms for smooth countdown
  }

  updateCountdown() {
    const secondsLeft = this.timeLeft.toFixed(1);
    this.countdownTarget.textContent = `Time remaining: ${secondsLeft}s`;
  }

  beforeSubmit(event) {
    const endTime = this.now;
    const responseTime = (endTime - this.clueDisplayTime) / 1000; // Convert to seconds
    this.timeFieldTarget.value = responseTime;
    this.clearIntervals();
  }

  disconnect() {
    this.clearIntervals();
  }

  clearIntervals() {
    if (this.responseInterval) {
      clearInterval(this.responseInterval); // FIX: Correct syntax
    }
  }
}
