require "test_helper"

class ClueTest < ActiveSupport::TestCase
  def setup
    @clue_one = clues(:one)
    @clue_two = clues(:two)
    @old = clues(:old)
  end

  test "valid round one clue" do
    assert @clue_one.valid?
  end
  test "valid round two clue" do
    assert @clue_two.valid?
  end

  test "invalid without round" do
    @clue_one.round = nil
    assert_not @clue_one.valid?
  end

  test "invalid without clue_value" do
    @clue_one.clue_value = nil
    assert_not @clue_one.valid?
  end

  test "normalizes old clue values" do
    old_clue = Clue.new(
      round: 1,
      clue_value: 100,
      category: "FOO",
      answer: "bar",
      question: "baz",
      air_date: "2001-11-25")
    assert old_clue.valid?
    assert_equal 200, old_clue.clue_value
  end

  test "does not modify new clue values" do
    assert_equal 200, @clue_one.clue_value
  end
end
