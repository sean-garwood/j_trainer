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
    post start_drills_path
    drill_id = session[:current_drill_id]
    assert_not_nil drill_id, "Expected a drill to be created"

    # End the drill
    @drill = Drill.find(drill_id)
    @drill.drill_clues.create!(clue: clues(:one), response: "Test", response_time: 2.0)
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
    post start_drills_path
    drill_id = session[:current_drill_id]

    # End the drill
    @drill = Drill.find(drill_id)
    @drill.drill_clues.create!(clue: clues(:one), response: "Test", response_time: 2.0)
    post end_drills_path
    follow_redirect!

    # Verify completion message
    assert_select "div", text: /Drill completed/i
  end

  test "train action shows filter configuration page" do
    # Request train page - should show filter configuration
    get train_drills_path
    assert_response :success

    # Verify no drill was created yet (train just shows the form)
    assert_nil session[:current_drill_id], "Expected no drill to be created yet"
  end

  test "start action creates drill with filters" do
    # Start a drill with filters
    post start_drills_path, params: { round: 1, clue_values: [ 200, 400 ] }

    # Verify drill was created
    drill_id = session[:current_drill_id]
    assert_not_nil drill_id, "Expected a drill to be created"

    # Verify filters were saved
    drill = Drill.find(drill_id)
    assert_equal "1", drill.filters["round"]
    assert_equal [ 200, 400 ], drill.filters["clue_values"]
  end
end
