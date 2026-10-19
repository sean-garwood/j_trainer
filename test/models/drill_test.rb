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

  test "stats coryat is the signed sum of normalized values" do
    drill = Drill.create!(user: users(:one))
    low = clues(:one).normalized_clue_value
    high = clues(:two).normalized_clue_value
    add_results(drill, one: :correct, two: :incorrect, three: :correct, new: :pass)

    stats = drill.stats
    assert_equal low - high + high, stats.coryat
    assert_equal [ 4, 2, 1, 1 ], [ stats.seen, stats.correct, stats.incorrect, stats.passed ]
    assert_equal 50.0, stats.accuracy
  end

  test "stats max_possible uses normalized clue values" do
    drill = Drill.create!(user: users(:one))
    add_results(drill, old: :correct)

    # old is a pre-2001 clue; its normalized value is what counts
    normalized = clues(:old).normalized_clue_value
    assert_includes ALL_CLUE_VALUES, normalized
    assert_equal normalized, drill.stats.max_possible
    assert_equal normalized, drill.stats.coryat
  end

  test "stats for a drill without clues are all zero" do
    stats = Drill.create!(user: users(:one)).stats

    assert_equal Drill::Stats.new(seen: 0, correct: 0, incorrect: 0, passed: 0, coryat: 0, max_possible: 0), stats
    assert_equal 0.0, stats.accuracy
  end

  private

    # insert_all skips ResponseJudge so results can be set directly
    def add_results(drill, results)
      rows = results.map do |clue, result|
        { drill_id: drill.id, clue_id: clues(clue).id, result: DrillClue.results[result] }
      end
      DrillClue.insert_all!(rows)
    end
end
