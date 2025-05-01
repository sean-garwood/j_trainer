require "test_helper"

class DrillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # sign in the user
    post session_path, params: { email_address: @user.email_address, password: 'password' }
    # set the session cookie
  end
  test "drill index" do
    get drills_path
    assert_response :success
  end

  test "drill new" do
    get new_drill_path
    assert_response :success
  end
end
