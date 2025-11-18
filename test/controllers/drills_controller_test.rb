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

  test "only index drills for current user" do
    get drills_path
    assert_response :success
    # assert that the response contains only drills for the current user
    user_drills_count = @user.drills.count
    new_drill = users(:two).drills.create!
    assert_equal 2, users(:two).drills.count
    # +1 for the summary row
    assert_select "tbody>tr", count: user_drills_count + 1
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

  test "ends current drill successfully" do
    # Start a training session to create a current drill
    get train_drills_path
    drill_id = session[:current_drill_id]
    assert_not_nil drill_id, "Expected a drill to be created"

    # End the drill
    post end_drills_path
    assert_response :redirect

    # Verify the drill was marked as ended
    drill = Drill.find(drill_id)
    assert_not_nil drill.ended_at, "Expected ended_at to be set"

    # Verify session was cleared
    assert_nil session[:current_drill_id], "Expected current_drill_id to be cleared from session"

    # Verify redirect to drill show page
    assert_redirected_to drill_path(drill)
    follow_redirect!
    assert_response :success
  end

  test "cannot end drill when no active drill exists" do
    # Ensure no active drill in session
    assert_nil session[:current_drill_id]

    # Attempt to end drill
    post end_drills_path
    assert_response :redirect
    assert_redirected_to drills_path

    # Verify alert message
    follow_redirect!
    assert_select "div", text: /No active drill to end/i
  end

  test "end drill shows completion notice" do
    # Start a training session
    get train_drills_path
    drill_id = session[:current_drill_id]

    # End the drill
    post end_drills_path
    follow_redirect!

    # Verify completion message
    assert_select "div", text: /Drill completed/i
  end

  test "invalidates cache when cached drill no longer exists" do
    # Manually set a non-existent drill_id in session
    non_existent_id = 999999
    session[:current_drill_id] = non_existent_id

    # Request train page - should handle missing drill gracefully
    get train_drills_path
    assert_response :success

    # Verify that a new drill was created
    new_drill_id = session[:current_drill_id]
    assert_not_nil new_drill_id, "Expected a new drill to be created"
    assert_not_equal non_existent_id, new_drill_id, "Expected session to be updated with new drill"

    # Verify the new drill exists
    assert Drill.exists?(new_drill_id), "Expected new drill to exist in database"
  end
end
