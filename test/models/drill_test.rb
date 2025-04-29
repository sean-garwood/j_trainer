require "test_helper"

class DrillTest < ActiveSupport::TestCase
  test "requires a user" do
    drill = drills(:one)
    drill.user = nil
    assert_not drill.valid?
  end
end
