require "test_helper"

class DrillTest < ActiveSupport::TestCase
  test "requires a user" do
    drill = drills(:one)
    drill.user = nil
    assert_not drill.valid?
  end

  test "calculates clues seen count" do
    drill = drills(:one)
    assert_equal drill.clues_seen_count, 3
  end
end
