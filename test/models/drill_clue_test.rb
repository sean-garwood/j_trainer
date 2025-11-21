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

  test "correctly identifies pass from 'pass' response" do
    drill_clue = DrillClue.new(
      drill: drills(:one),
      clue: clues(:one),
      response: "pass",
      response_time: 0
    )
    drill_clue.save

    assert drill_clue.pass?, "'pass' response should be marked as pass"
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
end
