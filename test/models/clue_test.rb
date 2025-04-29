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

  test "invalidates rounds out of range" do
    clue = clues(:invalid_round)
    assert_not clue.valid?
  end

  test "invalidates clue values out of range" do
    clue = clues(:invalid_clue_value)
    assert_not clue.valid?
  end

  test "invalid without clue_value" do
    @clue_one.clue_value = nil
    assert_not @clue_one.valid?
  end

  test "invalid without category" do
    clue = @clue_one
    clue.category = nil
    assert_not clue.valid?
  end

  test "invalid without answer" do
    clue = @clue_one
    clue.answer = nil
    assert_not clue.valid?
  end

  test "invalid without question" do
    clue = @clue_one
    clue.question = nil
    assert_not clue.valid?
  end

  test "invalid without air_date" do
    clue = @clue_one
    clue.air_date = nil
    assert_not clue.valid?
  end

  test "normalizes old clue values" do
    old_clue = @clue_one
    old_clue.air_date = "2001-11-25"
    old_clue.clue_value = 100
    assert old_clue.valid?
    assert_equal 200, old_clue.clue_value
  end

  test "does not modify new clue values" do
    assert_equal 200, @clue_one.clue_value
  end
end
