import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["timeField", "input", "countdown"];
    // TODO: unmagic defaults
    static values = {
        maxResponseTime: { type: Number, default: 15 },
    };

    get now() {
        return new Date().getTime();
    }

    connect() {
        this.clueDisplayTime = this.now;
        this.responseTime = null;
        this.maxResponseTime = this.maxResponseTimeValue;
        this.startResponseCountdown();
    }

    startResponseCountdown() {
        this.timeLeft = this.maxResponseTime;
        this.updateCountdown();

        const countdown = setInterval(() => {
            this.timeLeft -= 1;
            this.updateCountdown();

            if (this.timeLeft <= 0) {
                clearInterval(this.responseInterval);
                this.countdownTarget.textContent = "Time's up!";
                this.inputTarget.disabled = true;
                this.timeFieldTarget.value = this.maxResponseTime;
                // FIXIT: does not seem to submit the request properly
                this.element.requestSubmit();
            }
        }, 1000);
        this.responseInterval = countdown;
    }

    updateCountdown() {
        const secondsLeft = this.timeLeft.toFixed();
        this.countdownTarget.textContent = `Time remaining: ${secondsLeft}s`;
    }

    beforeSubmit(event) {
        const endTime = this.now;
        const responseTime = (endTime - this.clueDisplayTime) / 1000;
        this.timeFieldTarget.value = responseTime;
        this.clearIntervals();
    }

    disconnect() {
        this.clearIntervals();
    }

    clearIntervals() {
        if (this.responseInterval) {
            clearInterval(this.responseInterval);
        }
    }
}
