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
    assert_not @drill_clue.valid?
  end

  test "sets result" do
    clue = clues(:one)
    question = clue.question
    @drill_clue = DrillClue
      .new(drill: drills(:one), response_time: 1,
           clue: clue, response: question)
    @drill_clue.save
    assert @drill_clue.correct?
  end
end
