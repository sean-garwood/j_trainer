require "test_helper"

class ClueTest < ActiveSupport::TestCase
  def setup
    @clue_one = clues(:one)
    @clue_two = clues(:two)
    @old = clues(:old)
  end

  test "does not modify new clue values" do
    assert_equal 200, @clue_one.clue_value
  end

  test "responds to drill_clues" do
    assert_respond_to @clue_one, :drill_clues
  end
end
