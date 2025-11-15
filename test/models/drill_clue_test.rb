require "test_helper"

class DrillClueTest < ActiveSupport::TestCase
  test "validates presence of clue" do
    @drill_clue = DrillClue.new(clue: nil)
    assert_not @drill_clue.valid?
    assert_includes @drill_clue.errors[:clue], "must exist"
  end

  test "validates presence of drill" do
    @drill_clue = DrillClue.new(drill: nil)
    assert_not @drill_clue.valid?
    assert_includes @drill_clue.errors[:drill], "must exist"
  end

  test "validates response time is acceptable" do
    @drill_clue = DrillClue.new(response_time: 16)
    assert_not @drill_clue.valid? "validated even though response time is too high"
  end

  test "sets result" do
    clue = clues(:one)
    correct_response = clue.correct_response
    @drill_clue = DrillClue
      .new(drill: drills(:one), response_time: 1,
           clue: clue, response: correct_response)
    @drill_clue.save
    assert @drill_clue.correct?, "should be correct"
  end

  test "correctly identifies pass from blank response" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "",
      response_time: 0
    )
    drill_clue.save

    assert drill_clue.passed?, "Blank response should be marked as pass"
  end

  test "correctly identifies pass from 'pass' response" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "pass",
      response_time: 0
    )
    drill_clue.save

    assert drill_clue.passed?, "'pass' response should be marked as pass"
  end

  test "correctly identifies pass from 'p' response" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "p",
      response_time: 0
    )
    drill_clue.save

    assert drill_clue.passed?, "'p' response should be marked as pass"
  end

  test "correctly identifies pass from timeout" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "some answer",
      response_time: 10  # Greater than MAX_BUZZ_TIME (5s)
    )
    drill_clue.save

    assert drill_clue.passed?, "Timeout should be marked as pass"
  end

  test "response matching is case insensitive" do
    clue = clues(:one)  # correct_response: "What is the Jordan?"

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
    clue = clues(:three)  # correct_response: "What is C++?"

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "c++",  # Without question mark or "What is"
      response_time: 2.0
    )
    drill_clue.save

    assert drill_clue.correct?, "Should handle punctuation in matching"
  end

  test "partial response matches full answer" do
    clue = clues(:one)  # correct_response: "What is the Jordan?"

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "jordan",  # Partial match
      response_time: 2.0
    )
    drill_clue.save

    assert drill_clue.correct?, "Should match partial responses"
  end

  test "incorrect answer is marked as incorrect" do
    clue = clues(:one)

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "Wrong answer",
      response_time: 2.0
    )
    drill_clue.save

    assert drill_clue.incorrect?, "Wrong answer should be marked as incorrect"
  end

  test "validates response_time on update" do
    drill_clue = DrillClue.create!(
      drill: drills(:one),
      clue: clues(:one),
      response: "test",
      response_time: 1.0
    )

    # Try to update with invalid response time
    drill_clue.response_time = 999
    assert_not drill_clue.valid?, "Should not be valid with response_time > MAX_RESPONSE_TIME"
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

  test "normalized answer removes What is prefix" do
    clue = clues(:two)  # correct_response: "Who is Abraham Lincoln?"

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "Abraham Lincoln",  # Without "Who is"
      response_time: 2.0
    )
    drill_clue.save

    assert drill_clue.correct?, "Should match answer without 'Who is' prefix"
  end
end
