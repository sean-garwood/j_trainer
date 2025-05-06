require "test_helper"

class DrillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # sign in the user
    post session_path, params: { email_address: @user.email_address, password: "password" }
    # set the session cookie
  end
  test "gets drill index" do
    get drills_path
    assert_response :success
  end

  test "gets drill new" do
    get new_drill_path
    assert_response :success
  end

  test "only index drills for current user" do
    get drills_path
    assert_response :success
    # assert that the response contains only drills for the current user
    user_drills_count = @user.drills.count
    new_drill = users(:two).drills.create!
    assert_equal 2, users(:two).drills.count
    assert_select "tbody>tr", count: user_drills_count
    new_drill.destroy!
  end

  test "does not show another user's drill" do
    forbidden_drill = drills(:two)
    assert_raises CanCan::AccessDenied do
      get drill_path(forbidden_drill)
    end
  end

  test "gets drill train" do
    get train_drills_path
    assert_response :success
  end
end
