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

    assert drill_clue.pass?, "Blank response should be marked as pass"
  end

  test "'pass' is NOT a pass — it is judged as a normal response" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "pass",
      response_time: 0
    )
    drill_clue.save

    assert_not drill_clue.pass?, "'pass' should not be treated as a pass"
  end

  test "correctly identifies pass from 'p' response" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "p",
      response_time: 0
    )
    drill_clue.save

    assert drill_clue.pass?, "'p' response should be marked as pass"
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

  test "persists score and reason on save" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "jordan",
      response_time: 1.0
    )
    drill_clue.save

    assert drill_clue.correct?
    assert_not_nil drill_clue.score
    assert_not_nil drill_clue.reason
  end

  test "token subset: last name matches full name" do
    clue = clues(:two)  # correct_response: "Who is Abraham Lincoln?"

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "Lincoln",
      response_time: 1.0
    )
    drill_clue.save

    assert drill_clue.correct?, "Last name should match full name"
    assert_equal "token_subset", drill_clue.reason
  end

  test "typo tolerance: minor misspelling accepted" do
    clue = clues(:two)  # correct_response: "Who is Abraham Lincoln?"

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "Abrham Lincoln",
      response_time: 1.0
    )
    drill_clue.save

    assert drill_clue.correct?, "Minor misspelling should be accepted"
    assert_includes %w[spelling per_token_spelling], drill_clue.reason
  end

  test "short substring does not falsely match" do
    clue = clues(:two)  # correct_response: "Who is Abraham Lincoln?"

    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clue,
      response: "ham",
      response_time: 1.0
    )
    drill_clue.save

    assert drill_clue.incorrect?, "'ham' should not match 'Abraham Lincoln'"
  end
end
