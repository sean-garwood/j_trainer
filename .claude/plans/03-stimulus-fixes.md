# Module 3: Stimulus Controller Fixes

## Goal

Fix bugs in the existing `response_timer_controller.js` and simplify the timer logic for MVP.

## Files to Modify

- `/app/javascript/controllers/response_timer_controller.js`

---

## Current Issues

The existing Stimulus controller has several bugs:

1. **Line 12**: Missing `return` statement in `now()` getter
2. **Line 20**: Typo `MaxResponseTimeValue` should be `maxResponseTimeValue`
3. **Line 81**: `timeLeft` is not defined in scope
4. **Line 89**: Incorrect loop syntax for clearing intervals

---

## Corrected Version

```javascript
// app/javascript/controllers/response_timer_controller.js

import { Controller } from "@hotwired/stimulus";
import { MAX_RESPONSE_TIME, MAX_BUZZ_TIME } from "../constants";

export default class extends Controller {
  static targets = ["timeField", "input", "countdown"];
  static values = {
    maxResponseTime: Number,
    maxBuzzTime: Number,
  };

  get now() {
    return new Date().getTime(); // FIX: Added return
  }

  connect() {
    this.clueDisplayTime = this.now;
    this.responseTime = null;
    this.inputTarget.focus();
    this.maxBuzzTime = this.maxBuzzTimeValue || MAX_BUZZ_TIME;
    this.maxResponseTime = this.maxResponseTimeValue || MAX_RESPONSE_TIME; // FIX: Typo
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
```

---

## Key Changes

### 1. Fixed `now()` Getter

**Before:**
```javascript
get now() {
  new Date().getTime();
}
```

**After:**
```javascript
get now() {
  return new Date().getTime();
}
```

### 2. Fixed Typo in Variable Name

**Before:**
```javascript
this.maxResponseTime = this.MaxResponseTimeValue || MAX_RESPONSE_TIME;
```

**After:**
```javascript
this.maxResponseTime = this.maxResponseTimeValue || MAX_RESPONSE_TIME;
```

### 3. Fixed Scope Issue

**Before:**
```javascript
startResponseCountdown() {
  this.updateCountdown(); // timeLeft not defined yet!
  // ...
}
```

**After:**
```javascript
startResponseCountdown() {
  this.timeLeft = this.maxResponseTime; // Define first
  this.updateCountdown();
  // ...
}
```

### 4. Fixed `clearIntervals()` Method

**Before:**
```javascript
clearIntervals() {
  for (let interval in this.intervals) {
    clearInterval(interval);
  }
}
```

**After:**
```javascript
clearIntervals() {
  if (this.responseInterval) {
    clearInterval(this.responseInterval);
  }
}
```

---

## How It Works

### 1. Controller Initialization (`connect`)

- Records the timestamp when clue is displayed
- Focuses the input field
- Loads max response time from HTML data attributes or constants
- Starts the countdown timer

### 2. Countdown Timer (`startResponseCountdown`)

- Initializes `timeLeft` with max response time (e.g., 15 seconds)
- Updates display every 100ms for smooth countdown
- When time expires:
  - Disables input field
  - Sets response time to max value
  - Auto-submits the form

### 3. Form Submission (`beforeSubmit`)

- Triggered by Turbo event: `turbo:submit-start`
- Calculates actual response time: `(endTime - startTime) / 1000`
- Populates hidden `response_time` field
- Clears timer interval

### 4. Cleanup (`disconnect`)

- Clears any running timers when controller is removed from DOM
- Prevents memory leaks

---

## Stimulus Targets & Values

### Targets

```javascript
static targets = ["timeField", "input", "countdown"];
```

- **`timeField`**: Hidden input field for `response_time`
- **`input`**: Text input field for user's answer
- **`countdown`**: Display element for timer (e.g., "Time remaining: 12.4s")

### Values

```javascript
static values = {
  maxResponseTime: Number,
  maxBuzzTime: Number,
};
```

- **`maxResponseTime`**: Maximum time allowed to respond (15s default)
- **`maxBuzzTime`**: Maximum time to buzz in (5s, currently unused in MVP)

These can be set via HTML data attributes:
```erb
<form data-response-timer-max-response-time-value="20">
```

---

## Testing Checklist

- [ ] Timer starts on page load
- [ ] Countdown displays correctly (e.g., "Time remaining: 14.9s")
- [ ] Timer updates smoothly every 0.1 seconds
- [ ] Form auto-submits when timer expires
- [ ] Response time is captured in hidden field on submission
- [ ] Input field gets disabled when time expires
- [ ] Timer cleans up when navigating away
- [ ] Manual submission (before timer expires) captures correct response time
- [ ] Pass button works without waiting for timer

---

## Future Enhancements (Out of MVP Scope)

### 1. Buzz-In Logic

Add a two-phase timer:
1. Buzz-in phase (5s) - user must click "Buzz" button
2. Response phase (15s) - user types answer

```javascript
startBuzzCountdown() {
  this.buzzTimeLeft = this.maxBuzzTime;
  // Show "Buzz In" button
  // Start countdown
  // If timer expires, auto-pass
}
```

### 2. Keyboard Shortcuts

```javascript
handleKeyboard(event) {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    this.element.requestSubmit();
  }
  if (event.key === "Escape") {
    event.preventDefault();
    document.querySelector("a[href*='pass']")?.click();
  }
}
```

### 3. Sound Effects

```javascript
playBeep() {
  const audio = new Audio('/sounds/beep.mp3');
  audio.play();
}
```

---

## Notes

- Simplified to remove buzz-in logic for MVP
- Can be re-added later if desired
- Timer is client-side only (server calculates its own response time if needed)
- Uses `requestSubmit()` instead of `submit()` to trigger validations
