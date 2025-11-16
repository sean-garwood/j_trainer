# Handoff Instructions for Web Instance

## 📊 Task Completion Status

### ✅ COMPLETED: Modules 1-3 (100%)

| Module | Status | Files | Description |
|--------|--------|-------|-------------|
| **Module 1** | ✅ Complete | 3 files | Controller refactoring |
| **Module 2** | ✅ Complete | 3 files | Form and views with Turbo |
| **Module 3** | ✅ Complete | 1 file | Stimulus controller fixes |

### 🚧 REMAINING: Modules 4-6 (0%)

| Module | Status | Files | Description |
|--------|--------|-------|-------------|
| **Module 4** | 🚧 Not Started | 2 files | Model validations & auto-judging |
| **Module 5** | 🚧 Not Started | 4+ files | Comprehensive test suite |
| **Module 6** | 🚧 Not Started | Various | Polish, linting, security |

---

## 🎯 What's Been Completed

### Module 1: Controller Refactoring ✅

**Files Modified:**
- ✅ `app/controllers/drills_controller.rb` (lines 20-49)
- ✅ `config/routes.rb` (line 17)

**Files Created:**
- ✅ `app/controllers/drill_clues_controller.rb` (new file, 44 lines)

**What Works:**
- DrillsController#train fetches clues without saving DrillClue
- Session-based drill tracking (users can close/reopen browser)
- DrillCluesController handles response submissions
- Nested route: `POST /drills/:drill_id/drill_clues`
- Authorization via CanCanCan
- Drill completion redirects to results page

---

### Module 2: Form and Views ✅

**Files Modified:**
- ✅ `app/views/drills/train.html.erb` (complete rewrite, 45 lines)

**Files Created:**
- ✅ `app/views/drills/_clue_form.html.erb` (67 lines)
- ✅ `app/views/drill_clues/create.turbo_stream.erb` (28 lines)

**What Works:**
- Turbo Frame wrapper for seamless clue progression
- Real-time stats display (correct/incorrect/passed/seen)
- Beautiful Tailwind-styled clue cards
- Form with proper hidden fields (clue_id, response_time)
- Timer countdown display area
- Pass button functionality
- Game settings JSON injection for JavaScript
- Turbo Stream updates stats after each submission

---

### Module 3: Stimulus Controller Fixes ✅

**Files Modified:**
- ✅ `app/javascript/controllers/response_timer_controller.js` (64 lines)

**Bugs Fixed:**
1. ✅ Line 12: Added missing `return` in `now()` getter
2. ✅ Line 20: Fixed typo `MaxResponseTimeValue` → `maxResponseTimeValue`
3. ✅ Line 25: Fixed scope issue with `timeLeft` (now instance property)
4. ✅ Line 89: Fixed `clearIntervals()` loop syntax

**What Works:**
- Timer counts down from max response time (15s default)
- Display updates every 100ms: "Time remaining: X.Xs"
- Auto-submits form when timer expires
- Captures actual response time in seconds
- Cleans up intervals on disconnect
- Input field gets disabled on timeout

---

## 📋 Step-by-Step Instructions for Remaining Work

### STEP 1: Verify Current Implementation (15 minutes)

**Before starting new work, confirm what's already working:**

```bash
# 1. Start the development server
./bin/dev

# 2. Open browser to http://localhost:3000

# 3. Login or create a user account

# 4. Navigate to /drills/train

# 5. Check the following:
```

**Verification Checklist:**
- [ ] Page loads without errors
- [ ] Clue displays with category, value, round, and text
- [ ] Timer countdown appears and updates
- [ ] Form has response input field
- [ ] Pass button is visible
- [ ] Stats display shows zeros (0 correct, 0 incorrect, etc.)

**Check Browser Console:**
- [ ] No JavaScript errors
- [ ] No missing asset errors
- [ ] `game-settings-data` script tag is present

**If you see errors:**
- Check Rails logs in terminal
- Check browser console for JavaScript errors
- Verify all files from Modules 1-3 exist
- Verify `config/game_settings.yml` exists

---

### STEP 2: Implement Module 4 - Model Updates (1-2 hours)

**Goal:** Add validations and auto-judging logic to DrillClue model

**Plan Document:** `.claude/plans/04-model-updates.md`

#### Task 4.1: Read Current DrillClue Model

```bash
# Read the current model to understand what exists
cat app/models/drill_clue.rb
```

#### Task 4.2: Add Validations

**File:** `app/models/drill_clue.rb`

**Add these validations:**

```ruby
class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue

  # Validations
  validates :clue_id, presence: true
  validates :drill_id, presence: true
  validates :response_time,
    presence: true,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: JTrainer::MAX_RESPONSE_TIME
    }
  validates :result,
    presence: true,
    inclusion: { in: %w[correct incorrect pass] }

  # Callbacks
  before_validation :judge_response, on: :create

  # Scopes
  scope :correct, -> { where(result: "correct") }
  scope :incorrect, -> { where(result: "incorrect") }
  scope :pass, -> { where(result: "pass") }

  private

  def judge_response
    # Auto-judge logic goes here (see next task)
  end
end
```

#### Task 4.3: Implement Auto-Judging Logic

**Read the plan:** `.claude/plans/04-model-updates.md` (lines 85-137)

**Add this method to DrillClue:**

```ruby
def judge_response
  # If response is blank or explicitly "pass", mark as pass
  if response.blank? || response.strip.downcase == "pass"
    self.result = "pass"
    return
  end

  # If response time exceeds buzz time, mark as incorrect
  if response_time.to_f > JTrainer::MAX_BUZZ_TIME
    self.result = "incorrect"
    return
  end

  # Normalize both strings for comparison
  user_answer = normalize_answer(response)
  correct_answer = normalize_answer(clue.correct_response)

  # Simple string comparison (case-insensitive, trimmed)
  if user_answer == correct_answer
    self.result = "correct"
  else
    self.result = "incorrect"
  end
end

def normalize_answer(str)
  return "" if str.blank?

  # Remove common prefixes like "What is", "Who is", etc.
  normalized = str.strip.downcase
  normalized.gsub!(/^(what|who|where|when|why|how) (is|are|was|were) /, "")

  # Remove articles
  normalized.gsub!(/^(the|a|an) /, "")

  # Remove trailing punctuation
  normalized.gsub!(/[?.!]+$/, "")

  # Normalize whitespace
  normalized.gsub!(/\s+/, " ")

  normalized.strip
end
```

#### Task 4.4: Test Auto-Judging Manually

```bash
# Open Rails console
rails console

# Test auto-judging logic
drill = Drill.first || Drill.create!(user: User.first)
clue = Clue.first

# Test correct answer
dc = DrillClue.new(drill: drill, clue: clue, response: clue.correct_response, response_time: 5)
dc.save
puts dc.result # Should be "correct"

# Test incorrect answer
dc = DrillClue.new(drill: drill, clue: clue, response: "Wrong answer", response_time: 5)
dc.save
puts dc.result # Should be "incorrect"

# Test pass
dc = DrillClue.new(drill: drill, clue: clue, response: "", response_time: 0)
dc.save
puts dc.result # Should be "pass"

# Test timeout
dc = DrillClue.new(drill: drill, clue: clue, response: "Answer", response_time: 6)
dc.save
puts dc.result # Should be "incorrect" (exceeded buzz time)
```

#### Task 4.5: Verify Drill Stats Update

```bash
# In Rails console
drill = Drill.first
puts drill.stats # Should show correct counts

# Submit a few responses via the UI
# Then check stats again
drill.reload
puts drill.stats # Should reflect new submissions
```

**Expected Output:**
```ruby
{
  correct: 2,
  incorrect: 1,
  pass: 1,
  seen: 4,
  accuracy: "50.0%"
}
```

---

### STEP 3: Implement Module 5 - Testing (2-3 hours)

**Goal:** Write comprehensive test suite

**Plan Document:** `.claude/plans/05-testing.md`

#### Task 5.1: Write DrillClue Model Tests

**File:** `test/models/drill_clue_test.rb`

**Tests to write:**
- [ ] Validates presence of drill_id, clue_id, response_time, result
- [ ] Validates response_time is numeric and in valid range
- [ ] Validates result is one of: correct, incorrect, pass
- [ ] Tests auto-judging for correct answers
- [ ] Tests auto-judging for incorrect answers
- [ ] Tests auto-judging for pass (blank response)
- [ ] Tests auto-judging for timeout (response_time > MAX_BUZZ_TIME)
- [ ] Tests answer normalization (removes "What is", articles, etc.)
- [ ] Tests scopes: `.correct`, `.incorrect`, `.pass`

#### Task 5.2: Write DrillsController Tests

**File:** `test/controllers/drills_controller_test.rb`

**Tests to write:**
- [ ] GET /drills/train creates new drill if none exists
- [ ] GET /drills/train reuses existing drill from session
- [ ] GET /drills/train fetches a clue
- [ ] GET /drills/train redirects when no more clues
- [ ] GET /drills/train sets @drill_clue (unsaved)
- [ ] Authorization: requires logged-in user

#### Task 5.3: Write DrillCluesController Tests

**File:** `test/controllers/drill_clues_controller_test.rb`

**Tests to write:**
- [ ] POST /drills/:drill_id/drill_clues creates DrillClue
- [ ] POST saves response and response_time
- [ ] POST auto-judges response (correct/incorrect/pass)
- [ ] POST fetches next clue after submission
- [ ] POST ends drill when no more clues
- [ ] POST returns Turbo Stream format
- [ ] POST updates drill stats (correct_count, etc.)
- [ ] Authorization: can only submit to own drills

#### Task 5.4: Write Integration Test

**File:** `test/integration/drill_flow_test.rb`

**Full user flow test:**
1. User visits /drills/train
2. Sees clue displayed
3. Submits correct answer
4. Sees next clue (without page reload)
5. Stats update (1 correct, 1 seen)
6. Submits incorrect answer
7. Stats update (1 correct, 1 incorrect, 2 seen)
8. Passes on a clue
9. Stats update (1 correct, 1 incorrect, 1 pass, 3 seen)
10. Runs out of clues
11. Redirects to drill results page

#### Task 5.5: Run Tests

```bash
# Run all tests
rails test

# Run specific test files
rails test test/models/drill_clue_test.rb
rails test test/controllers/drills_controller_test.rb
rails test test/controllers/drill_clues_controller_test.rb
rails test test/integration/drill_flow_test.rb

# Run system tests (if any)
rails test:system
```

**Expected Result:** All tests pass ✅

---

### STEP 4: Implement Module 6 - Polish (1 hour)

**Goal:** UX improvements, linting, security

**Plan Document:** `.claude/plans/06-polish.md`

#### Task 6.1: Add Visual Feedback for Answers

**Enhancement:** Flash correct/incorrect feedback before next clue

**Option 1: CSS Animation (Simple)**

Add to `app/views/drill_clues/create.turbo_stream.erb`:

```erb
<%# Flash feedback before replacing content %>
<%= turbo_stream.append "drill_clue_frame" do %>
  <div class="fixed top-20 left-1/2 transform -translate-x-1/2 z-50
              <%= @drill_clue.result == 'correct' ? 'bg-green-500' : 'bg-red-500' %>
              text-white px-6 py-3 rounded-lg shadow-lg animate-fade-out">
    <%= @drill_clue.result == 'correct' ? '✓ Correct!' : '✗ Incorrect' %>
  </div>
<% end %>

<%= turbo_stream.replace "drill_clue_frame" do %>
  <%= render "drills/clue_form", drill: @drill, clue: @clue, drill_clue: @drill_clue %>
<% end %>
```

**Option 2: Stimulus Controller (Advanced)**

See `.claude/plans/06-polish.md` for full implementation.

#### Task 6.2: Run RuboCop

```bash
# Run RuboCop on all Ruby files
bundle exec rubocop -a

# Fix any remaining offenses manually
bundle exec rubocop

# Expected: 0 offenses
```

**If offenses remain:**
- Read each offense carefully
- Fix manually or use `-A` for aggressive auto-correction
- Ensure code still works after fixes

#### Task 6.3: Run Brakeman Security Scan

```bash
# Run security scan
bundle exec brakeman

# Expected: 0 warnings
```

**If warnings appear:**
- Read each warning carefully
- Fix security issues (SQL injection, XSS, etc.)
- Re-run scan to verify

#### Task 6.4: Manual QA Checklist

**Test in browser:**
- [ ] Timer counts down smoothly
- [ ] Correct answer → next clue appears
- [ ] Incorrect answer → next clue appears
- [ ] Pass button → next clue appears
- [ ] Stats update in real-time
- [ ] Last clue → redirects to results
- [ ] Can resume drill after closing browser
- [ ] No JavaScript errors in console
- [ ] Works with browser back button
- [ ] Input field gets focus on page load
- [ ] Form auto-submits on timeout

---

## 🛠️ Troubleshooting Common Issues

### Issue: "No clues available" on first load

**Cause:** Database has no clues

**Fix:**
```bash
# Check if clues exist
rails console
Clue.count

# If zero, import from TSV
rails db:seed # (if seed file exists)
# OR manually import
```

### Issue: Timer doesn't start

**Cause:** JavaScript error or missing constants

**Fix:**
```javascript
// Check browser console
// Look for: "Cannot read property 'max_response_time' of null"

// Verify game-settings-data script tag exists in HTML
document.getElementById('game-settings-data')
```

### Issue: Form submits but stats don't update

**Cause:** `update_counts!` callback not triggering

**Fix:**
```ruby
# In Rails console
drill = Drill.first
drill.update_counts!
drill.reload
drill.stats # Should show updated counts
```

### Issue: Auto-judging always marks incorrect

**Cause:** Answer normalization too aggressive or clue.correct_response format mismatch

**Fix:**
```ruby
# In Rails console
clue = Clue.first
puts clue.correct_response # Check format

# Test normalization
dc = DrillClue.new(drill: Drill.first, clue: clue, response: clue.correct_response, response_time: 5)
dc.send(:normalize_answer, clue.correct_response)
dc.send(:normalize_answer, dc.response)
# Should be equal
```

### Issue: Turbo Frame not replacing

**Cause:** Frame ID mismatch or missing Turbo Stream response

**Fix:**
```erb
<!-- Verify frame ID matches in both files -->
<!-- app/views/drills/train.html.erb -->
<%= turbo_frame_tag "drill_clue_frame" do %>

<!-- app/views/drill_clues/create.turbo_stream.erb -->
<%= turbo_stream.replace "drill_clue_frame" do %>
```

---

## 📚 Reference Documents

**All plans are in:** `.claude/plans/`

- `00-overview.md` - High-level architecture and decisions
- `01-controller-refactoring.md` - ✅ Completed
- `02-form-views.md` - ✅ Completed
- `03-stimulus-fixes.md` - ✅ Completed
- `04-model-updates.md` - 🚧 Next to implement
- `05-testing.md` - 🚧 After Module 4
- `06-polish.md` - 🚧 Final polish
- `99-reference.md` - Risk assessment and file summary

**Status tracking:** `.claude/IMPLEMENTATION_STATUS.md`

---

## ✅ Success Criteria

**You're done when:**

1. ✅ Users can view clues one at a time in training mode
2. ✅ Users can submit answers via form
3. ✅ Responses are correctly judged as correct/incorrect/pass (Module 4)
4. ✅ Next clue loads seamlessly without page refresh
5. ✅ Timer counts down and auto-submits on expiry
6. ✅ Stats update accurately after each response (Module 4)
7. ✅ Drill ends gracefully when no more clues
8. ✅ All tests pass (`rails test`) (Module 5)
9. ✅ RuboCop has no offenses (Module 6)
10. ✅ Brakeman reports no security issues (Module 6)

---

## 🎯 Quick Start for Web Instance

```bash
# 1. Read this file
cat .claude/HANDOFF_INSTRUCTIONS.md

# 2. Verify current implementation
./bin/dev
# Visit http://localhost:3000/drills/train

# 3. Read Module 4 plan
cat .claude/plans/04-model-updates.md

# 4. Implement auto-judging
# Edit app/models/drill_clue.rb

# 5. Test manually in console
rails console

# 6. Move to Module 5 (testing)
# Write tests in test/ directory

# 7. Run all tests
rails test

# 8. Polish (Module 6)
bundle exec rubocop -a
bundle exec brakeman

# 9. Final manual QA
# Test full flow in browser

# 10. Done! 🎉
```

---

## 📝 Notes for Web Instance

- **Do NOT rewrite completed modules** - Modules 1-3 are done and working
- **Follow the plans exactly** - They've been carefully designed
- **Test as you go** - Don't wait until the end to test
- **Ask questions if unclear** - Better to clarify than guess
- **Keep commits atomic** - One module per commit
- **Run tests frequently** - Catch issues early

Good luck! The hardest parts (UI, Turbo, Stimulus) are done. What remains is primarily backend logic and testing. 🚀
