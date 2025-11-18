require "test_helper"

class ClueValueTest < ActiveSupport::TestCase
  def setup
    @old = clues(:old)
    @new = clues(:new)
  end

  test "normalizes old clue values" do
    normalized = ClueValueNormalizer.normalize_clue_value(@old.clue_value, @old.air_date)
    assert_equal 200, normalized
  end

  test "does not normalize new clue values" do
    normalized = ClueValueNormalizer.normalize_clue_value(@new.clue_value, @new.air_date)
    assert_equal 200, normalized  # Assuming fixture has 200
  end
end
