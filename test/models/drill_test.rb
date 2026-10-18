require "test_helper"

class DrillTest < ActiveSupport::TestCase
  test "requires a user" do
    @drill = drills(:one)
    @drill.user = nil
    assert_not @drill.valid?
  end

  test "clues seen count" do
    @drill = drills(:one)
    assert_equal 0, @drill.clues_seen_count
    @drill.drill_clues << drill_clues(:one)
    @drill.save
    assert_equal 1, @drill.clues_seen_count
  end

  test "incorrect count" do
    @drill = drills(:one)
    assert_equal 0, @drill.clues_seen_count
    @drill.drill_clues << drill_clues(:one)
    @drill.save
    assert_equal 1, @drill.incorrect_count
  end

  test "correct count" do
    @drill = drills(:two)
    @drill.drill_clues << drill_clues(:two)
    @drill.save
    assert_equal 1, @drill.correct_count
  end

  test "deleting drill does not delete the clue" do
    @drill = drills :two
    @clues = @drill.clues
    assert some_clue_id = @clues.first.id
    @drill.destroy
    clue = Clue.find(some_clue_id)
    assert clue, "Clue gone"
  end

  # TODO: might wanna do DrillStats first.
  # test "coryat score" do
  #   @drill = drills(:one)
  # end
end
