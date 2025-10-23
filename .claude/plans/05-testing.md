# Module 5: Testing Strategy

## Goal

Write comprehensive tests for all new functionality: controllers, models, and system tests for the full workflow.

## Files to Create

- `/test/controllers/drill_clues_controller_test.rb`
- `/test/system/drills_test.rb`

## Files to Modify

- `/test/models/drill_clue_test.rb` (add tests)

---

## 1. Controller Tests

### File: `/test/controllers/drill_clues_controller_test.rb`

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

  test "should update drill counts after submission" do
    initial_count = @drill.clues_seen_count

    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: @clue.correct_response,
        response_time: 1.5
      }
    }

    @drill.reload
    assert_equal initial_count + 1, @drill.clues_seen_count
  end

  test "should not allow unauthorized user to submit" do
    other_user = users(:two)
    other_drill = Drill.create!(user: other_user)

    assert_raises(CanCan::AccessDenied) do
      post drill_drill_clues_path(other_drill), params: {
        drill_clue: {
          clue_id: @clue.id,
          response: "test",
          response_time: 1.0
        }
      }
    end
  end
end
```

### What We're Testing

- ✅ Creates DrillClue records correctly
- ✅ Auto-judges responses (correct/incorrect/pass)
- ✅ Returns Turbo Stream response format
- ✅ Handles drill completion (no more clues)
- ✅ Updates drill counts via callback
- ✅ Enforces authorization (CanCanCan)

---

## 2. Model Tests

### File: `/test/models/drill_clue_test.rb` (add to existing file)

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

test "correctly identifies pass from 'p' response" do
  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clues(:one),
    response: "p",
    response_time: 0
  )
  drill_clue.save

  assert drill_clue.passed?
end

test "updates drill counts after save" do
  drill = drills(:one)
  initial_correct = drill.correct_count
  initial_seen = drill.clues_seen_count

  DrillClue.create!(
    drill: drill,
    clue: clues(:one),
    response: clues(:one).question,
    response_time: 1.0
  )

  drill.reload
  assert_equal initial_correct + 1, drill.correct_count
  assert_equal initial_seen + 1, drill.clues_seen_count
end

test "response matching is case insensitive" do
  clue = clues(:one)
  # Assume clue.correct_response = "the Jordan"

  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clue,
    response: "JORDAN",  # All caps
    response_time: 2.0
  )
  drill_clue.save

  assert drill_clue.correct?, "Should match regardless of case"
end

test "response matching handles punctuation" do
  clue = Clue.create!(
    round: 1,
    clue_value: 200,
    category: "Programming",
    answer: "A popular programming language",
    question: "What is C++?",
    air_date: Date.today
  )

  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clue,
    response: "c++",  # Without spaces
    response_time: 2.0
  )
  drill_clue.save

  assert drill_clue.correct?, "Should handle punctuation in matching"
end

test "partial response matches full answer" do
  clue = clues(:one)
  # Assume clue.correct_response = "the Jordan River"

  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clue,
    response: "jordan",  # Partial match
    response_time: 2.0
  )
  drill_clue.save

  assert drill_clue.correct?, "Should match partial responses"
end

test "validates response_time on save" do
  drill_clue = DrillClue.create!(
    drill: drills(:one),
    clue: clues(:one),
    response: "test",
    response_time: 1.0
  )

  # Try to update with invalid response time
  drill_clue.response_time = 999
  assert_not drill_clue.valid?
  assert_includes drill_clue.errors[:response_time], "must be between 0 and #{JTrainer::MAX_RESPONSE_TIME} seconds"
end

test "allows new record without response_time" do
  drill_clue = DrillClue.new(
    drill: drills(:one),
    clue: clues(:one),
    response: "test"
    # No response_time set
  )

  assert drill_clue.valid?, "Should allow new records without response_time"
end
```

### What We're Testing

- ✅ Pass detection (blank, "pass", "p")
- ✅ Drill count updates via callback
- ✅ Case-insensitive matching
- ✅ Punctuation handling
- ✅ Partial matches
- ✅ Response time validation
- ✅ New record validation behavior

---

## 3. System Tests

### File: `/test/system/drills_test.rb`

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
    assert_selector "div[data-response-timer-target='countdown']"

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

  test "displays clue information" do
    visit train_drills_path

    # Should show category, value, and clue text
    assert_selector "h2" # Category
    assert_selector "div", text: /\$[\d,]+/ # Dollar value
    assert_selector "div.bg-blue-900" # Clue text container
  end

  test "displays stats" do
    visit train_drills_path

    # Should show stats
    assert_text "Correct"
    assert_text "Incorrect"
    assert_text "Passed"
    assert_text "Seen"
  end

  test "timer countdown displays" do
    visit train_drills_path

    # Timer should start
    assert_selector "div[data-response-timer-target='countdown']", text: /Time remaining: \d+\.\d+s/
  end

  test "completing drill shows results" do
    # Stub to return no clues
    Drill.any_instance.stubs(:fetch_clue).returns(nil)

    visit train_drills_path

    # Should see completion message
    assert_text "No more clues available!"
    assert_link "View Results"
  end

  test "autofocus on response input" do
    visit train_drills_path

    # Input should be focused
    assert_equal "drill_clue_response", page.evaluate_script("document.activeElement.id")
  end
end
```

### What We're Testing

- ✅ Full workflow (view clue → submit → next clue)
- ✅ Pass button functionality
- ✅ Clue information display (category, value, text)
- ✅ Stats display
- ✅ Timer countdown
- ✅ Drill completion
- ✅ Autofocus behavior

---

## 4. Fixtures

Make sure you have appropriate test fixtures set up.

### File: `/test/fixtures/clues.yml`

```yaml
one:
  round: 1
  clue_value: 200
  category: "Geography"
  answer: "River mentioned most often in the Bible"
  question: "the Jordan"
  air_date: 2024-01-01

two:
  round: 1
  clue_value: 400
  category: "History"
  answer: "This president was assassinated in 1865"
  question: "Abraham Lincoln"
  air_date: 2024-01-02
```

### File: `/test/fixtures/drills.yml`

```yaml
one:
  user: one
  created_at: <%= 1.hour.ago %>
  correct_count: 0
  incorrect_count: 0
  pass_count: 0
  clues_seen_count: 0
```

---

## Running Tests

### Run All Tests

```bash
rails test
```

### Run Specific Test File

```bash
rails test test/controllers/drill_clues_controller_test.rb
rails test test/models/drill_clue_test.rb
rails test test/system/drills_test.rb
```

### Run Single Test

```bash
rails test test/controllers/drill_clues_controller_test.rb:15
```

### Run System Tests Only

```bash
rails test:system
```

---

## Test Coverage Goals

| Test Type | Coverage Target | Priority |
|-----------|----------------|----------|
| Unit Tests (Models) | 100% | High |
| Controller Tests | 90%+ | High |
| System Tests | Key user paths | Medium |
| Integration Tests | Manual for MVP | Low |

---

## Common Test Failures & Fixes

### Failure: "No route matches"

**Cause**: Routes not configured correctly

**Fix**: Check `config/routes.rb` has nested route:
```ruby
resources :drills do
  resources :drill_clues, only: [:create]
end
```

### Failure: "CanCan::AccessDenied"

**Cause**: Authorization not set up in test

**Fix**: Use `sign_in_as(@user)` in setup or stub authorization:
```ruby
controller.stubs(:authorize!).returns(true)
```

### Failure: Turbo Stream tests

**Cause**: Need to set Accept header

**Fix**:
```ruby
headers: { "Accept" => "text/vnd.turbo-stream.html" }
```

### Failure: System tests timing out

**Cause**: JavaScript not loading or Turbo frames not updating

**Fix**: Add explicit waits:
```ruby
assert_selector "input[name='drill_clue[response]']", wait: 5
```

---

## Testing Checklist

- [ ] All controller tests pass
- [ ] All model tests pass
- [ ] All system tests pass
- [ ] Test coverage is adequate (90%+ for models/controllers)
- [ ] Authorization tests included
- [ ] Edge cases tested (blank responses, invalid times, etc.)
- [ ] Turbo Frame behavior tested
- [ ] Timer functionality tested (if possible)

---

## Notes

- Use fixtures for common test data
- Mock/stub external dependencies (e.g., `fetch_clue` returning nil)
- System tests run slower - focus on critical user paths
- JavaScript tests can be manual for MVP
- Consider adding integration tests for Turbo behavior later
