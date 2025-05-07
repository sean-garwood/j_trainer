import { Controller } from "@hotwired/stimulus";
import { MAX_RESPONSE_TIME, MAX_BUZZ_TIME } from "../constants";

export default class extends Controller {
  static targets = ["timeField", "buzzTimeField", "input", "countdown"];
  static values = {
    maxResponseTime: MAX_RESPONSE_TIME,
    maxBuzzTime: MAX_BUZZ_TIME,
  };

  get now() {
    new Date().getTime();
  }

  connect() {
    this.clueDisplayTime = this.now;
    this.buzzTime = null;
    this.inputTarget.focus();
    this.maxBuzzTime = this.maxBuzzTimeValue || MAX_BUZZ_TIME;
    this.maxResponseTime = this.MaxResponseTimeValue || MAX_RESPONSE_TIME;
    this.startBuzzCountdown();
  }

  buzzIn() {
    if (!this.buzzTime) {
      this.buzzTime = this.now - this.clueDisplayTime;
      this.buzzTimeFieldTarget.value = this.buzzTime;

      clearInterval(this.buzzInterval);
      this.startResponseCountdown();
    }
  }

  startBuzzCountdown() {
    let timeLeft = this.maxBuzzTime;

    this.countdownTarget.textContent = this.#countdown("Buzz in?");
    this.buzzInterval = setInterval(() => {
      timeLeft -= 0.1;
      this.countdownTarget.textContent = ``;

      if (timeLeft <= 0) {
        clearInterval(this.buzzInterval);
        this.countdownTarget.textContent = "Time's up!";
        this.timeFieldTarget.value = this.maxBuzzTime * 1000;
        this.element.requestSubmit();
      }
    }, 100);
  }

  startResponseCountdown() {
    let timeLeft = this.maxResponseTime;
    this.countdownTarget.textContent = this.#countdown("Answer!");

    this.responseInterval = setInterval(() => {
      timeLeft -= 0.1;
      this.countdownTarget.textContent = this.#countdown("Answer!");

      if (timeLeft <= 0) {
        clearInterval(this.responseInterval);
        this.countdownTarget.textContent = "Time's up!";
        this.inputTarget.disabled = true; // nil input == pass
        this.timeFieldTarget.value = this.maxResponseTime * 1000;
        this.element.requestSubmit();
      }
    }, 100);
  }

  beforeSubmit(e) {
    const endTime = this.now;
    const responseTime = endTime - this.clueDisplayTime;
    this.timeFieldTarget.value = responseTime;
    this.#clearIntervals();
  }

  disconnect() {
    this.#clearIntervals();
  }

  #countdown(prefix) {
    const secondsLeft = timeLeft.toFixed(1);

    return `${prefix} ${secondsLeft}s`;
  }

  #clearIntervals() {
    const intervals = [this.buzzInterval, this.responseInterval];

    for (const interval in intervals) {
      clearInterval(interval);
    }
  }
}
