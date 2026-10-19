require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "accuracy_class colors by threshold" do
    assert_equal "text-green-600", accuracy_class(70)
    assert_equal "text-yellow-600", accuracy_class(69.99)
    assert_equal "text-yellow-600", accuracy_class(50)
    assert_equal "text-red-600", accuracy_class(49.99)
  end
end
