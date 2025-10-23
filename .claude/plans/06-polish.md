# Module 6: Polish & Enhancements

## Goal

Add UX improvements, visual feedback, and optional features to make the training experience more engaging.

**Note**: These are all **optional** enhancements for after the MVP is working.

---

## Enhancement 1: Visual Feedback Animation

Show a brief flash of green (correct) or red (incorrect) before transitioning to the next clue.

### File: `/app/javascript/controllers/feedback_controller.js` (create)

```javascript
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  showCorrect() {
    this.flash("bg-green-100 border-green-500", "✓ Correct!");
  }

  showIncorrect() {
    this.flash("bg-red-100 border-red-500", "✗ Incorrect");
  }

  flash(classes, message) {
    const feedback = document.createElement("div");
    feedback.className = `fixed top-4 right-4 p-4 rounded-lg border-2 ${classes} text-lg font-bold animate-pulse z-50`;
    feedback.textContent = message;

    document.body.appendChild(feedback);

    setTimeout(() => {
      feedback.remove();
    }, 1500);
  }
}
```

### Usage

Trigger from Turbo Stream response:

```erb
<%# In create.turbo_stream.erb %>

<%= turbo_stream.append "body" do %>
  <div data-controller="feedback"
       data-action="turbo:frame-load@window->feedback#showCorrect">
  </div>
<% end %>
```

Or trigger manually via JavaScript after form submission.

---

## Enhancement 2: Keyboard Shortcuts

Add keyboard shortcuts for better UX: Enter to submit, Escape to pass.

### Update: `/app/javascript/controllers/response_timer_controller.js`

```javascript
connect() {
  // ... existing code ...
  this.keyboardListener = this.handleKeyboard.bind(this);
  document.addEventListener("keydown", this.keyboardListener);
}

disconnect() {
  // ... existing code ...
  document.removeEventListener("keydown", this.keyboardListener);
}

handleKeyboard(event) {
  // Enter to submit (if not holding Shift)
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    this.element.requestSubmit();
  }

  // Escape to pass
  if (event.key === "Escape") {
    event.preventDefault();
    const passLink = document.querySelector("a[href*='pass']");
    if (passLink) passLink.click();
  }
}
```

### User Guide

Add a help tooltip or keyboard shortcuts reference:

```erb
<div class="text-sm text-gray-500 mt-4">
  <strong>Keyboard shortcuts:</strong>
  Enter = Submit | Esc = Pass
</div>
```

---

## Enhancement 3: Loading States

Add visual indication when loading next clue.

### CSS

```css
/* In app/assets/stylesheets/application.tailwind.css */

.turbo-progress-bar {
  background-color: #4f46e5; /* Indigo-600 */
}

/* Add spinner animation */
@keyframes spin {
  to { transform: rotate(360deg); }
}

.spinner {
  animation: spin 1s linear infinite;
}
```

### HTML

```erb
<div data-turbo-frame="drill_clue_frame">
  <div class="flex justify-center items-center py-12">
    <div class="spinner border-4 border-indigo-200 border-t-indigo-600 rounded-full w-12 h-12"></div>
  </div>
</div>
```

---

## Enhancement 4: Sound Effects

Add audio cues for correct/incorrect answers and timer expiration.

### Setup

1. Add sound files to `/app/assets/sounds/`:
   - `correct.mp3`
   - `incorrect.mp3`
   - `beep.mp3`

2. Create audio controller:

```javascript
// app/javascript/controllers/audio_controller.js

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  playCorrect() {
    this.playSound("/assets/correct.mp3");
  }

  playIncorrect() {
    this.playSound("/assets/incorrect.mp3");
  }

  playBeep() {
    this.playSound("/assets/beep.mp3");
  }

  playSound(url) {
    const audio = new Audio(url);
    audio.volume = 0.5;
    audio.play().catch(err => {
      // User hasn't interacted with page yet
      console.log("Audio autoplay prevented:", err);
    });
  }
}
```

3. Add to form:

```erb
<div data-controller="audio"
     data-action="drill:correct->audio#playCorrect drill:incorrect->audio#playIncorrect">
</div>
```

---

## Enhancement 5: Stats Update via Turbo Streams

Update stats in real-time without refreshing the entire page.

### Update: `/app/views/drills/train.html.erb`

Add an ID to the stats div:

```erb
<div id="drill_stats" class="bg-white rounded-lg shadow p-4 flex gap-4 text-sm">
  <!-- Stats content -->
</div>
```

### Update: `/app/views/drill_clues/create.turbo_stream.erb`

Already includes stats update:

```erb
<%= turbo_stream.update "drill_stats" do %>
  <%= render "drills/stats", drill: @drill %>
<% end %>
```

### Create: `/app/views/drills/_stats.html.erb`

Extract stats to partial:

```erb
<div class="bg-white rounded-lg shadow p-4 flex gap-4 text-sm">
  <div class="text-center">
    <div class="font-bold text-green-600"><%= drill.correct_count %></div>
    <div class="text-gray-600">Correct</div>
  </div>
  <div class="text-center">
    <div class="font-bold text-red-600"><%= drill.incorrect_count %></div>
    <div class="text-gray-600">Incorrect</div>
  </div>
  <div class="text-center">
    <div class="font-bold text-gray-600"><%= drill.pass_count %></div>
    <div class="text-gray-600">Passed</div>
  </div>
  <div class="text-center">
    <div class="font-bold text-blue-600"><%= drill.clues_seen_count %></div>
    <div class="text-gray-600">Seen</div>
  </div>
</div>
```

---

## Enhancement 6: Turbo Frame Caching

Disable caching for the drill frame to prevent stale clues.

### Update: `/app/views/drills/train.html.erb`

```erb
<%= turbo_frame_tag "drill_clue_frame", data: { turbo_cache: false } do %>
  <%# ... %>
<% end %>
```

---

## Enhancement 7: Disable Submit on Click

Prevent double-submissions by disabling the submit button after first click.

### Update Form

```erb
<%= form.submit "Submit Answer",
                data: { turbo_submits_with: "Submitting..." },
                class: "..." %>
```

Turbo will automatically disable the button and show "Submitting..." text during submission.

---

## Enhancement 8: Progress Bar

Show progress through the drill (e.g., "Question 5 of 20").

### Update: `/app/views/drills/train.html.erb`

```erb
<div class="mb-4">
  <div class="text-sm text-gray-600">
    Question <%= @drill.clues_seen_count + 1 %> of <%= @drill.total_clues %>
  </div>
  <div class="w-full bg-gray-200 rounded-full h-2">
    <div class="bg-indigo-600 h-2 rounded-full transition-all"
         style="width: <%= (@drill.clues_seen_count.to_f / @drill.total_clues * 100).round %>%">
    </div>
  </div>
</div>
```

**Note**: Requires adding `total_clues` to Drill model or passing it in.

---

## Enhancement 9: Mobile Optimizations

Make the form more touch-friendly.

### CSS Updates

```css
/* Larger touch targets on mobile */
@media (max-width: 768px) {
  input[type="text"] {
    font-size: 16px; /* Prevents iOS zoom */
    padding: 1rem;
  }

  button, a.btn {
    min-height: 44px; /* iOS recommended minimum */
  }
}
```

### HTML Updates

```erb
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
```

---

## Enhancement 10: Accessibility Improvements

### ARIA Labels

```erb
<%= form.text_field :response,
                    "aria-label": "Your answer",
                    "aria-describedby": "timer-countdown" %>

<div id="timer-countdown"
     data-response-timer-target="countdown"
     role="timer"
     aria-live="polite">
</div>
```

### Skip Link

```erb
<a href="#main-content" class="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

### Focus Management

```javascript
// In response_timer_controller.js

connect() {
  // ... existing code ...
  this.inputTarget.focus();
  this.inputTarget.setAttribute("aria-describedby", "timer-countdown");
}
```

---

## Enhancement 11: Error Handling

Show user-friendly error messages if submission fails.

### Update: `/app/controllers/drill_clues_controller.rb`

```ruby
def create
  @drill_clue = @drill.drill_clues.build(drill_clue_params)

  if @drill_clue.save
    # ... existing code ...
  else
    # Render error state
    @clue = @drill_clue.clue
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("drill_clue_frame",
          partial: "drills/clue_form",
          locals: { drill: @drill, clue: @clue, drill_clue: @drill_clue })
      end
      format.html { render "drills/train", status: :unprocessable_entity }
    end
  end
end
```

### Update Form to Show Errors

```erb
<% if drill_clue.errors.any? %>
  <div class="bg-red-50 border border-red-200 rounded p-4 mb-4">
    <ul class="list-disc list-inside text-red-700">
      <% drill_clue.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

---

## Implementation Priority

### High Priority (Do These First)
- [x] Keyboard shortcuts (Enter/Escape)
- [x] Loading states (Turbo progress bar)
- [x] Disable submit button on click
- [x] Stats update via Turbo Streams

### Medium Priority
- [ ] Visual feedback animation (green/red flash)
- [ ] Error handling
- [ ] Mobile optimizations
- [ ] Turbo Frame caching disabled

### Low Priority (Nice to Have)
- [ ] Sound effects
- [ ] Progress bar
- [ ] Accessibility improvements (ARIA, skip links)

---

## Testing Polish Features

- [ ] Test keyboard shortcuts (Enter, Escape)
- [ ] Test loading states appear
- [ ] Test stats update in real-time
- [ ] Test on mobile devices (touch targets, font sizes)
- [ ] Test with screen reader (accessibility)
- [ ] Test error states (validation failures)
- [ ] Test double-submission prevention

---

## Notes

- Most of these are **optional** - MVP works without them
- Prioritize based on user feedback
- Some features (sound, animations) may be distracting - make them toggleable
- Test thoroughly on mobile before deploying mobile optimizations
- Keep accessibility in mind from the start - easier than retrofitting
