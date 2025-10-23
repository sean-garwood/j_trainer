# Module 2: Form and Views

## Goal

Build the interactive training form with Turbo Frames for seamless clue progression without page reloads.

## Files to Modify

- `/app/views/drills/train.html.erb`

## Files to Create

- `/app/views/drills/_clue_form.html.erb`
- `/app/views/drill_clues/create.turbo_stream.erb`

---

## Step 1: Update Main Train View

**File**: `/app/views/drills/train.html.erb`

### Code

```erb
<div class="max-w-4xl mx-auto mt-8 p-6">
  <div class="mb-6 flex justify-between items-center">
    <h1 class="text-3xl font-bold">Training Session</h1>

    <!-- Stats Display (static for now) -->
    <div class="bg-white rounded-lg shadow p-4 flex gap-4 text-sm">
      <div class="text-center">
        <div class="font-bold text-green-600"><%= @drill.correct_count %></div>
        <div class="text-gray-600">Correct</div>
      </div>
      <div class="text-center">
        <div class="font-bold text-red-600"><%= @drill.incorrect_count %></div>
        <div class="text-gray-600">Incorrect</div>
      </div>
      <div class="text-center">
        <div class="font-bold text-gray-600"><%= @drill.pass_count %></div>
        <div class="text-gray-600">Passed</div>
      </div>
      <div class="text-center">
        <div class="font-bold text-blue-600"><%= @drill.clues_seen_count %></div>
        <div class="text-gray-600">Seen</div>
      </div>
    </div>
  </div>

  <%= turbo_frame_tag "drill_clue_frame" do %>
    <% if @clue.present? %>
      <%= render "clue_form", drill: @drill, clue: @clue, drill_clue: @drill_clue %>
    <% else %>
      <div class="text-center py-12">
        <p class="text-xl text-gray-600">No more clues available!</p>
        <%= link_to "View Results", drill_path(@drill),
                    class: "mt-4 inline-block px-6 py-3 bg-indigo-600 text-white rounded-lg" %>
      </div>
    <% end %>
  <% end %>
</div>

<!-- Inject game settings for JavaScript -->
<script id="game-settings-data" type="application/json">
  <%= raw({
    max_response_time: JTrainer::MAX_RESPONSE_TIME,
    max_buzz_time: JTrainer::MAX_BUZZ_TIME
  }.to_json) %>
</script>
```

### Key Points

- **Turbo Frame**: `drill_clue_frame` wraps the form and will be replaced on submission
- **Stats Display**: Shows real-time counts (will be updated via Turbo Streams later)
- **Game Settings**: JSON script tag provides config for JavaScript timer
- **Conditional Rendering**: Shows "no more clues" message when drill is complete

---

## Step 2: Create Clue Form Partial

**File**: `/app/views/drills/_clue_form.html.erb`

### Code

```erb
<div class="bg-white rounded-lg shadow-lg p-8">
  <!-- Clue Display -->
  <div class="mb-8 text-center">
    <div class="mb-4">
      <span class="inline-block px-4 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
        <%= clue.round == 1 ? "Jeopardy!" : clue.round == 2 ? "Double Jeopardy!" : "Final Jeopardy!" %>
      </span>
    </div>

    <h2 class="text-2xl font-bold text-indigo-900 mb-2"><%= clue.category %></h2>
    <div class="text-4xl font-bold text-green-600 mb-6">$<%= number_with_delimiter(clue.clue_value) %></div>

    <!-- Clue Text (this is the "answer" in Jeopardy format) -->
    <div class="bg-blue-900 text-white text-xl p-6 rounded-lg min-h-[120px] flex items-center justify-center">
      <%= clue.answer %>
    </div>
  </div>

  <!-- Response Form -->
  <%= form_with model: drill_clue,
                url: drill_drill_clues_path(drill),
                data: {
                  controller: "response-timer",
                  turbo_frame: "drill_clue_frame",
                  action: "turbo:submit-start->response-timer#beforeSubmit"
                },
                class: "space-y-4" do |form| %>

    <%= form.hidden_field :clue_id, value: clue.id %>
    <%= form.hidden_field :response_time,
                          value: 0,
                          data: { response_timer_target: "timeField" } %>

    <!-- User Response Input -->
    <div>
      <%= form.label :response, "What is...", class: "block text-sm font-medium text-gray-700 mb-2" %>
      <%= form.text_field :response,
                          placeholder: "Enter your answer (or leave blank to pass)",
                          autofocus: true,
                          autocomplete: "off",
                          data: { response_timer_target: "input" },
                          class: "w-full px-4 py-3 text-lg border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200" %>
    </div>

    <!-- Timer Display -->
    <div class="text-center">
      <div data-response-timer-target="countdown"
           class="text-2xl font-bold text-gray-700">
        Ready...
      </div>
    </div>

    <!-- Submit Buttons -->
    <div class="flex gap-3">
      <%= form.submit "Submit Answer",
                      class: "flex-1 px-6 py-3 bg-indigo-600 text-white font-semibold rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>

      <%= link_to "Pass",
                  drill_drill_clues_path(drill, drill_clue: { clue_id: clue.id, response: "pass", response_time: 0 }),
                  data: {
                    turbo_method: :post,
                    turbo_frame: "drill_clue_frame"
                  },
                  class: "px-6 py-3 bg-gray-300 text-gray-700 font-semibold rounded-lg hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2" %>
    </div>
  <% end %>
</div>
```

### Key Points About `form_with`

**Important `form_with` Details:**

1. **Model**: Pass the unsaved `drill_clue` instance for form builder
2. **URL**: Explicitly set to `drill_drill_clues_path(drill)` for nested route
3. **Turbo Frame**: `data: { turbo_frame: "drill_clue_frame" }` tells Turbo which frame to update
4. **Stimulus Controller**: `data: { controller: "response-timer" }` attaches the timer
5. **Turbo Event**: `turbo:submit-start->response-timer#beforeSubmit` captures response time before submission
6. **Hidden Fields**:
   - `clue_id`: Identifies which clue is being answered
   - `response_time`: Populated by JavaScript before submission

### Clue Display Notes

- **Shows `clue.answer`**: In Jeopardy! format, the "answer" is what's shown to players
- **User enters `question`**: The correct response (e.g., "What is the Jordan?")
- **Round Badge**: Displays Jeopardy!/Double Jeopardy!/Final Jeopardy!
- **Category & Value**: Prominent display for context

### Pass Button

- Uses `link_to` with `turbo_method: :post` to submit without filling form
- Submits `response: "pass"` with zero time
- Targets same Turbo Frame for seamless transition

---

## Step 3: Create Turbo Stream Response

**File**: `/app/views/drill_clues/create.turbo_stream.erb`

### Code

```erb
<%= turbo_stream.replace "drill_clue_frame" do %>
  <%= render "drills/clue_form",
             drill: @drill,
             clue: @clue,
             drill_clue: @drill_clue %>
<% end %>

<%# Optional: Update stats in real-time %>
<%= turbo_stream.update "drill_stats" do %>
  <div class="bg-white rounded-lg shadow p-4 flex gap-4 text-sm">
    <div class="text-center">
      <div class="font-bold text-green-600"><%= @drill.correct_count %></div>
      <div class="text-gray-600">Correct</div>
    </div>
    <div class="text-center">
      <div class="font-bold text-red-600"><%= @drill.incorrect_count %></div>
      <div class="text-gray-600">Incorrect</div>
    </div>
    <div class="text-center">
      <div class="font-bold text-gray-600"><%= @drill.pass_count %></div>
      <div class="text-gray-600">Passed</div>
    </div>
    <div class="text-center">
      <div class="font-bold text-blue-600"><%= @drill.clues_seen_count %></div>
      <div class="text-gray-600">Seen</div>
    </div>
  </div>
<% end %>
```

### Key Points

- **First Stream**: Replaces entire clue form with next clue
- **Second Stream (Optional)**: Updates stats display without replacing form
- Controller must set `@drill`, `@clue`, and `@drill_clue` for this to work
- If you want to update stats, add `id="drill_stats"` to the stats div in `train.html.erb`

---

## Testing Checklist

- [ ] Verify Turbo Frame targets correct element
- [ ] Verify form submits to correct nested route
- [ ] Verify hidden fields populate correctly
- [ ] Verify clue displays answer (not question)
- [ ] Verify Pass button works without typing
- [ ] Verify autofocus on response field
- [ ] Verify Turbo Stream replaces frame on submission
- [ ] Test with browser back button (should work)
- [ ] Test with disabled JavaScript (should gracefully degrade)

---

## Common `form_with` Gotchas

### Gotcha 1: Default `local: true` vs Remote

In Rails 7+, `form_with` defaults to remote (AJAX) submission. Turbo handles this automatically.

### Gotcha 2: Nested Routes

Always explicitly set `url:` for nested routes:
```erb
url: drill_drill_clues_path(drill)
```

### Gotcha 3: Model State

The model passed to `form_with` should be in the state you want:
- For new records: `DrillClue.new(drill: @drill, clue: @clue)`
- Form will POST to `drill_drill_clues_path`

### Gotcha 4: Turbo Frame Targeting

The form's `data-turbo-frame` attribute must match the wrapping frame's ID.

---

## Notes

- Partial is reusable: same form rendered initially and after each submission
- Turbo Frames keep the experience feeling like a single-page app
- No custom JavaScript needed for form submission (Turbo handles it)
- Stats update automatically via model callback to `update_counts!`
