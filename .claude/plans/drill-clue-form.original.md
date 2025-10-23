# Implementation Plan: Drill Training Form for J! Trainer

## Executive Summary

This plan outlines the implementation of an interactive training form for the J! Trainer application. The form will allow users to view Jeopardy! clues, submit answers, self-judge their responses, and progress through a drill session using Hotwire (Turbo Frames/Streams) for dynamic, seamless updates without full page reloads.

## Current State Analysis

### What Exists

1. **DrillsController#train**: Creates/retrieves a drill and fetches a clue, but currently creates DrillClue records immediately without capturing user responses
2. **DrillClue Model**: Tracks responses with:
   - `response` (string): User's answer
   - `response_time` (float): Time taken to answer
   - `result` (enum): correct (-1), pass (0), incorrect (1)
   - Auto-validation logic based on regex matching against clue.correct_response
3. **Stimulus Controller**: `response_timer_controller.js` exists with timer logic
4. **Game Settings**: Configurable buzz time (5s) and response time (15s)

### Problems Identified

1. **Controller Logic Flaw**: `train` action creates DrillClue records before user responds (line 39)
2. **Missing Form**: No form exists in `train.html.erb` (line 14-16 is placeholder)
3. **No Response Capture**: No mechanism to submit user answers
4. **No Self-Judging Flow**: No UI for users to confirm correct/incorrect/pass
5. **Incorrect Display**: Shows `@clue.clue_text` instead of `@clue.correct_response` (the clue text)

## Architecture Approach

### Hotwire Strategy

**Option A: Turbo Frames (Recommended)**
- Use Turbo Frames to replace clue + form content on submission
- Single frame wraps the entire clue/form section
- Server returns next clue + form in response
- Smooth transitions, maintains scroll position
- Simpler implementation

**Option B: Turbo Streams**
- Use Turbo Streams to update multiple page sections independently
- More granular control (update clue, form, stats separately)
- Better for real-time stat updates
- More complex implementation

**Decision**: Use **Turbo Frames** for MVP, with hooks for Turbo Streams later for live stats updates.

### Workflow Design

```
┌─────────────────────────────────────────────────────────────┐
│ 1. GET /drills/train                                        │
│    → Load drill, fetch clue, render form                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. User views clue (timer starts)                          │
│    → Display: category, value, clue text (answer)          │
│    → Input field for user response                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. User submits response (or timer expires)                │
│    → POST /drills/:id/drill_clues                          │
│    → Params: { drill_clue: { response, response_time } }   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Server creates DrillClue record                         │
│    → Auto-calculate result (correct/incorrect/pass)        │
│    → Fetch next clue                                       │
│    → Render Turbo Frame with next clue + form              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Turbo Frame replaces content                            │
│    → User sees next clue immediately                       │
│    → Repeat from step 2                                    │
└─────────────────────────────────────────────────────────────┘
```

### Self-Judging UI Flow

Since the DrillClue model already has auto-validation logic (`response_matches_correct_response?`), we have two options:

**Option A: Auto-Judge Only (Simpler)**
- Submit response → server auto-judges → show next clue
- Display brief feedback (green/red flash) before transitioning
- No user override needed

**Option B: Confirmation UI (User Override)**
- Submit response → show clue answer + user's response
- User clicks "Correct" / "Incorrect" / "Pass"
- Server updates result if user disagrees with auto-judge
- More complex but gives users control

**Decision**: Start with **Option A** (auto-judge), add Option B later if users want override capability.

---

## Detailed Implementation Plan

### Phase 1: Refactor Controller Logic

**Files to Modify:**
- `/home/ssg/repos/j_trainer/app/controllers/drills_controller.rb`

**Tasks:**

#### Step 1.1: Fix `train` Action Logic

**Current Problem**: Creates DrillClue before user responds

**Solution**: Remove DrillClue creation from `train`, only fetch and display clue

```ruby
# app/controllers/drills_controller.rb

def train
  @drill = find_or_create_current_drill
  @clue = @drill.fetch_clue

  if @clue.nil?
    end_drill
  else
    @drill_clue = DrillClue.new(drill: @drill, clue: @clue)
    # Don't save yet - wait for user response
  end
end

private

def find_or_create_current_drill
  if session[:current_drill_id].present?
    Drill.find(session[:current_drill_id])
  else
    drill = Drill.create!(user: current_user)
    session[:current_drill_id] = drill.id
    drill
  end
end

def end_drill
  current_drill = Drill.find(session[:current_drill_id])
  current_drill.update(ended_at: Time.current)
  session[:current_drill_id] = nil
  redirect_to drill_path(current_drill), notice: "Drill completed! Great work!"
end
```

#### Step 1.2: Create DrillCluesController

**File to Create:**
- `/home/ssg/repos/j_trainer/app/controllers/drill_clues_controller.rb`

**Purpose**: Handle user response submissions

```ruby
# app/controllers/drill_clues_controller.rb

class DrillCluesController < ApplicationController
  before_action :set_drill

  def create
    @drill_clue = @drill.drill_clues.build(drill_clue_params)

    if @drill_clue.save
      # Fetch next clue
      @clue = @drill.fetch_clue

      if @clue.nil?
        # No more clues - end drill
        @drill.update(ended_at: Time.current)
        session[:current_drill_id] = nil
        redirect_to drill_path(@drill), notice: "Drill completed!"
      else
        # Prepare next drill clue (unsaved)
        @drill_clue = DrillClue.new(drill: @drill, clue: @clue)

        # Render Turbo Frame with next clue
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to train_drills_path }
        end
      end
    else
      # Validation failed
      @clue = @drill_clue.clue
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_drill
    @drill = current_user.drills.find(params[:drill_id])
    authorize! :update, @drill
  end

  def drill_clue_params
    params.require(:drill_clue).permit(:clue_id, :response, :response_time)
  end
end
```

#### Step 1.3: Update Routes

**File to Modify:**
- `/home/ssg/repos/j_trainer/config/routes.rb`

```ruby
# config/routes.rb

resources :drills, except: %i[edit destroy] do
  collection do
    get :train
  end

  # Nested route for submitting responses
  resources :drill_clues, only: [:create]
end
```

---

### Phase 2: Build Form View

**Files to Create/Modify:**
- `/home/ssg/repos/j_trainer/app/views/drills/train.html.erb` (modify)
- `/home/ssg/repos/j_trainer/app/views/drills/_clue_form.html.erb` (create partial)
- `/home/ssg/repos/j_trainer/app/views/drill_clues/create.turbo_stream.erb` (create)

#### Step 2.1: Update Main Train View

**File**: `/home/ssg/repos/j_trainer/app/views/drills/train.html.erb`

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

#### Step 2.2: Create Clue Form Partial

**File**: `/home/ssg/repos/j_trainer/app/views/drills/_clue_form.html.erb`

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
      <%= clue.clue_text %>
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

#### Step 2.3: Create Turbo Stream Response

**File**: `/home/ssg/repos/j_trainer/app/views/drill_clues/create.turbo_stream.erb`

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

---

### Phase 3: Fix Stimulus Controller

**Files to Modify:**
- `/home/ssg/repos/j_trainer/app/javascript/controllers/response_timer_controller.js`

#### Issues to Fix:

1. Line 12: Missing `return` statement
2. Line 20: Typo `MaxResponseTimeValue` should be `maxResponseTimeValue`
3. Line 81: `timeLeft` is not defined in scope
4. Line 89: Incorrect loop syntax for clearing intervals

**Corrected Version:**

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
    this.timeLeft = this.maxResponseTime;
    this.updateCountdown();

    this.responseInterval = setInterval(() => {
      this.timeLeft -= 0.1;
      this.updateCountdown();

      if (this.timeLeft <= 0) {
        clearInterval(this.responseInterval);
        this.countdownTarget.textContent = "Time's up!";
        this.inputTarget.disabled = true;
        this.timeFieldTarget.value = this.maxResponseTime;
        this.element.requestSubmit();
      }
    }, 100);
  }

  updateCountdown() {
    const secondsLeft = this.timeLeft.toFixed(1);
    this.countdownTarget.textContent = `Time remaining: ${secondsLeft}s`;
  }

  beforeSubmit(e) {
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
      clearInterval(this.responseInterval);
    }
  }
}
```

**Note**: Simplified to remove buzz-in logic for MVP. Can add back later if needed.

---

### Phase 4: Database & Model Updates

**No schema changes needed** - existing fields are sufficient:
- `drill_clues.response` (string)
- `drill_clues.response_time` (float)
- `drill_clues.result` (enum)

#### Step 4.1: Fix Method Name Collision in DrillClue

**CRITICAL**: The model has TWO `passed?` methods - one public (line 24-26) checking the enum, and one private (line 48-50) checking the response string. This creates a conflict.

**Solution**: Rename the private method to `response_indicates_pass?`:

```ruby
# app/models/drill_clue.rb

private
  def set_result
    case true
    when response_matches_correct_response?
      self.result = :correct
    when response_indicates_pass?  # RENAMED to avoid collision
      self.result = :pass
    else
      self.result = :incorrect
    end
  end

  def response_indicates_pass?
    response.blank? || response.strip.match?(/\Ap(?:ass)?\z/i) || no_buzz?
  end
```

#### Step 4.2: Fix Validation Issue

**Problem**: Line 10 uses `except_on: :new` which is **not a valid Rails option**.

**Solution**: Use `unless: :new_record?` instead:

```ruby
validates :response_time,
  inclusion: {
    in: 0..JTrainer::MAX_RESPONSE_TIME,
    message: "must be between 0 and #{JTrainer::MAX_RESPONSE_TIME} seconds"
  },
  unless: :new_record?
```

#### Step 4.3: Review DrillClue Model Logic

The existing auto-validation logic has a potential issue:

```ruby
# Current implementation in app/models/drill_clue.rb (line 41)
def response_matches_correct_response?
  Regexp.new(clue.correct_response).match?(response)
end
```

**Problem**: Treats `clue.correct_response` as a regex pattern, which may fail if it contains special regex characters.

**Solution**: Use string matching or fuzzy matching instead. Note that in Jeopardy! format:
- `clue.clue_text` = "the Jordan" (what we SHOW users - the clue)
- `clue.correct_response` = "What is the Jordan?" or just "the Jordan" (the correct response)

```ruby
# Improved version - handles Jeopardy! format
def response_matches_correct_response?
  return false if response.blank?

  # Extract answer from "What is X?" format if present
  answer_text = clue.correct_response.gsub(/\A(what|who|where|when|why) is\s+/i, '').gsub(/\??\z/, '').strip

  # Normalize both strings: downcase, remove punctuation, trim
  normalized_response = response.downcase.gsub(/[^a-z0-9\s]/, '').strip
  normalized_answer = answer_text.downcase.gsub(/[^a-z0-9\s]/, '').strip

  # Check if response contains the key answer terms
  normalized_answer.include?(normalized_response) ||
    normalized_response.include?(normalized_answer)
end
```

#### Step 4.4: Note on Drill Model

**Good News**: The Drill model already has all the count methods we need:
- `correct_count` (database column)
- `incorrect_count` (database column)
- `pass_count` (database column)
- `clues_seen_count` (database column)

The `after_save :update_counts!` callback keeps these in sync. No changes needed!

---

### Phase 5: Testing Strategy

**Files to Create/Modify:**

#### Step 5.1: Controller Tests

**File**: `/home/ssg/repos/j_trainer/test/controllers/drill_clues_controller_test.rb`

```ruby
require "test_helper"

class DrillCluesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @drill = drills(:one)
    @clue = clues(:one)
    sign_in_as(@user)
  end

  test "should create drill_clue with correct answer" do
    assert_difference("DrillClue.count", 1) do
      post drill_drill_clues_path(@drill), params: {
        drill_clue: {
          clue_id: @clue.id,
          response: @clue.correct_response,
          response_time: 3.5
        }
      }
    end

    drill_clue = DrillClue.last
    assert drill_clue.correct?
    assert_equal 3.5, drill_clue.response_time
  end

  test "should create drill_clue with incorrect answer" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: "wrong answer",
        response_time: 2.0
      }
    }

    drill_clue = DrillClue.last
    assert drill_clue.incorrect?
  end

  test "should create drill_clue with pass" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: "pass",
        response_time: 0
      }
    }

    drill_clue = DrillClue.last
    assert drill_clue.passed?
  end

  test "should return turbo_stream response" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: @clue.correct_response,
        response_time: 1.0
      }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "turbo-stream", response.media_type
  end

  test "should redirect to drill show when no more clues" do
    # Stub fetch_clue to return nil
    Drill.any_instance.stubs(:fetch_clue).returns(nil)

    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: "test",
        response_time: 1.0
      }
    }

    assert_redirected_to drill_path(@drill)
    assert_equal "Drill completed!", flash[:notice]
  end
end
```

#### Step 5.2: Model Tests

**File**: `/home/ssg/repos/j_trainer/test/models/drill_clue_test.rb` (add tests)

```ruby
# Add to existing test file

test "correctly identifies pass from blank response" do
  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clues(:one),
    response: "",
    response_time: 0
  )
  drill_clue.save

  assert drill_clue.passed?
end

test "correctly identifies pass from 'pass' response" do
  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clues(:one),
    response: "pass",
    response_time: 0
  )
  drill_clue.save

  assert drill_clue.passed?
end

test "updates drill counts after save" do
  drill = drills(:one)
  initial_count = drill.clues_seen_count

  DrillClue.create!(
    drill: drill,
    clue: clues(:one),
    response: clues(:one).question,
    response_time: 1.0
  )

  drill.reload
  assert_equal initial_count + 1, drill.clues_seen_count
end
```

#### Step 5.3: System Tests

**File**: `/home/ssg/repos/j_trainer/test/system/drills_test.rb` (create)

```ruby
require "application_system_test_case"

class DrillsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "completing a drill workflow" do
    visit train_drills_path

    # Should see first clue
    assert_selector "h2", text: /.+/ # Category name
    assert_selector "input[name='drill_clue[response]']"

    # Submit an answer
    fill_in "drill_clue[response]", with: "test answer"
    click_button "Submit Answer"

    # Should see next clue (via Turbo Frame)
    assert_selector "h2", text: /.+/
    assert_selector "input[name='drill_clue[response]']"
  end

  test "passing a clue" do
    visit train_drills_path

    click_link "Pass"

    # Should advance to next clue
    assert_selector "input[name='drill_clue[response]']"
  end
end
```

---

### Phase 6: UI/UX Enhancements

#### Step 6.1: Add Visual Feedback

Create a brief feedback animation before transitioning to next clue:

**File**: `/home/ssg/repos/j_trainer/app/javascript/controllers/feedback_controller.js` (create)

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
    feedback.className = `fixed top-4 right-4 p-4 rounded-lg border-2 ${classes} text-lg font-bold animate-pulse`;
    feedback.textContent = message;

    document.body.appendChild(feedback);

    setTimeout(() => {
      feedback.remove();
    }, 1500);
  }
}
```

#### Step 6.2: Keyboard Shortcuts

Add keyboard shortcuts for better UX:

```javascript
// Add to response_timer_controller.js

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
  // Enter to submit
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    this.element.requestSubmit();
  }

  // Escape to pass
  if (event.key === "Escape") {
    event.preventDefault();
    document.querySelector("a[href*='pass']")?.click();
  }
}
```

#### Step 6.3: Loading States

Add Turbo loading indicators:

```erb
<!-- In application.html.erb layout -->
<%= turbo_stream_from "drill_updates" %>

<style>
  .turbo-progress-bar {
    background-color: #4f46e5; /* Indigo-600 */
  }
</style>
```

---

## Implementation Checklist

### Phase 1: Controller Refactoring
- [ ] Refactor `DrillsController#train` to not create DrillClue
- [ ] Create `DrillCluesController` with `create` action
- [ ] Add nested route `drills/:id/drill_clues`
- [ ] Add authorization checks to DrillCluesController
- [ ] Write controller tests

### Phase 2: View Implementation
- [ ] Update `train.html.erb` with Turbo Frame
- [ ] Create `_clue_form.html.erb` partial
- [ ] Create `create.turbo_stream.erb` response
- [ ] Add game settings JSON script tag
- [ ] Test Turbo Frame replacement in browser

### Phase 3: JavaScript Fixes
- [ ] Fix bugs in `response_timer_controller.js`
- [ ] Simplify timer logic (remove buzz-in for MVP)
- [ ] Test timer functionality
- [ ] Add keyboard shortcuts (optional)

### Phase 4: Model Updates
- [ ] Improve `response_matches_correct_response?` logic
- [ ] Simplify `passed?` method
- [ ] Add model tests for new logic
- [ ] Test edge cases (special characters, empty responses)

### Phase 5: Testing
- [ ] Write controller tests for DrillCluesController
- [ ] Add model tests for DrillClue
- [ ] Write system tests for full workflow
- [ ] Run full test suite: `rails test`
- [ ] Fix any failures

### Phase 6: Polish
- [ ] Add visual feedback animations
- [ ] Implement keyboard shortcuts
- [ ] Add loading states
- [ ] Test on different screen sizes
- [ ] Accessibility review (keyboard navigation, screen readers)

### Phase 7: Deployment Prep
- [ ] Run RuboCop: `bundle exec rubocop -a`
- [ ] Run Brakeman: `bundle exec brakeman`
- [ ] Performance check (N+1 queries, etc.)
- [ ] Update CLAUDE.md if needed
- [ ] Final manual testing

---

## Risk Assessment & Mitigation

### Risk 1: Turbo Frame Caching Issues
**Impact**: Medium
**Likelihood**: Medium
**Mitigation**:
- Use `data: { turbo_cache: false }` on drill frame
- Clear session storage on drill end
- Test with browser caching enabled

### Risk 2: Timer Drift/Inaccuracy
**Impact**: Low
**Likelihood**: High
**Mitigation**:
- Use server time for authoritative response_time
- Accept client-side timer is approximate
- Document acceptable variance in tests

### Risk 3: Race Conditions (Rapid Submissions)
**Impact**: High
**Likelihood**: Low
**Mitigation**:
- Disable submit button on first click
- Use optimistic locking on Drill model
- Add server-side duplicate detection

### Risk 4: DrillClue Validation Failures
**Impact**: Medium
**Likelihood**: Low
**Mitigation**:
- Handle validation errors gracefully in controller
- Render error messages in form
- Log validation failures for debugging

---

## Future Enhancements (Out of Scope)

1. **Self-Judging Override UI**: Allow users to override auto-judged results
2. **Answer Fuzzy Matching**: Use Levenshtein distance for typo tolerance
3. **Daily Doubles**: Support wager input for daily double clues
4. **Sound Effects**: Add audio cues for correct/incorrect/timer
5. **Achievements**: Award badges for streaks, perfect drills, etc.
6. **Drill Configuration**: Pre-drill screen to select categories, difficulty, count
7. **Multiplayer**: Real-time drill sessions with friends
8. **Mobile Optimizations**: Touch-friendly controls, PWA features

---

## Testing Requirements Summary

| Test Type | Files to Test | Priority | Coverage Target |
|-----------|--------------|----------|-----------------|
| Unit Tests | `DrillClue`, `Drill` | High | 100% |
| Controller Tests | `DrillsController`, `DrillCluesController` | High | 90%+ |
| System Tests | Full workflow | Medium | Key paths |
| Integration Tests | Turbo Frame behavior | Medium | Manual |
| JavaScript Tests | Stimulus controllers | Low | Manual (for MVP) |

---

## File Summary

### Files to Create (7)
1. `/home/ssg/repos/j_trainer/app/controllers/drill_clues_controller.rb`
2. `/home/ssg/repos/j_trainer/app/views/drills/_clue_form.html.erb`
3. `/home/ssg/repos/j_trainer/app/views/drill_clues/create.turbo_stream.erb`
4. `/home/ssg/repos/j_trainer/test/controllers/drill_clues_controller_test.rb`
5. `/home/ssg/repos/j_trainer/test/system/drills_test.rb`
6. `/home/ssg/repos/j_trainer/app/javascript/controllers/feedback_controller.js` (optional)

### Files to Modify (6)
1. `/home/ssg/repos/j_trainer/app/controllers/drills_controller.rb`
2. `/home/ssg/repos/j_trainer/app/models/drill_clue.rb`
3. `/home/ssg/repos/j_trainer/app/views/drills/train.html.erb`
4. `/home/ssg/repos/j_trainer/app/javascript/controllers/response_timer_controller.js`
5. `/home/ssg/repos/j_trainer/config/routes.rb`
6. `/home/ssg/repos/j_trainer/test/models/drill_clue_test.rb`

### No Database Migrations Needed
Existing schema supports all required fields.

---

## Estimated Complexity

- **Phase 1 (Controller)**: 2-3 hours
- **Phase 2 (Views)**: 3-4 hours
- **Phase 3 (JavaScript)**: 1-2 hours
- **Phase 4 (Models)**: 1 hour
- **Phase 5 (Testing)**: 3-4 hours
- **Phase 6 (Polish)**: 2-3 hours

**Total**: 12-17 hours for complete implementation and testing

---

## Success Criteria

The implementation will be considered successful when:

1. ✅ Users can view clues one at a time in training mode
2. ✅ Users can submit answers via form
3. ✅ Responses are correctly judged as correct/incorrect/pass
4. ✅ Next clue loads seamlessly without page refresh
5. ✅ Timer counts down and auto-submits on expiry
6. ✅ Stats update accurately after each response
7. ✅ Drill ends gracefully when no more clues
8. ✅ All tests pass (`rails test`)
9. ✅ RuboCop has no offenses
10. ✅ Brakeman reports no security issues

---

This plan provides a complete roadmap for implementing the drill training form with modern Rails/Hotwire patterns, comprehensive testing, and room for future enhancements. The phased approach allows for iterative development and validation at each step.