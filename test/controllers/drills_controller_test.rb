require "test_helper"

class DrillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post sign_in_path, params: { email_address: @user.email_address, password: "password" }
  end
  test "gets drill index" do
    get drills_path
    assert_response :success
  end

  test "only index drills for current user" do
    get drills_path
    assert_response :success
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
    post start_drills_path
    drill_id = session[:current_drill_id]
    assert_not_nil drill_id, "Expected a drill to be created"

    @drill = Drill.find(drill_id)
    @drill.drill_clues.create!(clue: clues(:one), response: "Test", response_time: 2.0)
    post end_drills_path
    assert_response :redirect

    drill = Drill.find(drill_id)
    assert_not_nil drill.ended_at, "Expected ended_at to be set"

    assert_nil session[:current_drill_id], "Expected current_drill_id to be cleared from session"

    assert_redirected_to drill_path(drill)
    follow_redirect!
    assert_response :success
  end

  test "cannot end drill when no active drill exists" do
    assert_nil session[:current_drill_id]

    post end_drills_path
    assert_response :redirect
    assert_redirected_to drills_path

    follow_redirect!
    assert_select "div", text: /No active drill to end/i
  end

  test "end drill shows completion notice" do
    post start_drills_path
    drill_id = session[:current_drill_id]

    @drill = Drill.find(drill_id)
    @drill.drill_clues.create!(clue: clues(:one), response: "Test", response_time: 1.0)
    post end_drills_path
    follow_redirect!

    assert_select "div", text: /Drill completed/i
  end

  test "train action shows filter configuration page" do
    get train_drills_path
    assert_response :success

    assert_nil session[:current_drill_id], "Expected no drill to be created yet"
  end

  test "GET start redirects to train page" do
    get start_drills_path
    assert_redirected_to "/drills/train"
  end

  test "show with non-numeric id redirects to drills index" do
    get drill_path("abc")
    assert_redirected_to drills_path
    follow_redirect!
    assert_select "div", text: /Invalid drill ID/i
  end

  test "training view uses viewport-height layout without page scroll" do
    post start_drills_path
    assert_response :success
    assert_select "[class*='overflow-hidden']"
    assert_select "[class*='flex'][class*='flex-col']"
  end

  test "training view stats bar is outside scroll area" do
    post start_drills_path
    assert_response :success
    assert_select "#drill_stats"
  end

  test "show page renders styled stats cards" do
    drill = drills(:one)
    drill.drill_clues.create!(clue: clues(:one), response: "test", response_time: 1.0) if drill.drill_clues.empty?
    get drill_path(drill)
    assert_response :success
    assert_select ".bg-gray-50"
    assert_select ".grid"
    assert_select "div", /Coryat/
  end

  test "show page renders color-coded result badges for drill clues" do
    drill = drills(:one)
    drill.drill_clues.create!(clue: clues(:two), response: "Abraham Lincoln", response_time: 1.0)
    get drill_path(drill)
    assert_response :success
    assert_select ".bg-green-100"
    assert_select ".bg-red-100"
  end

  test "header uses Jeopardy blue theme" do
    get drills_path
    assert_response :success
    assert_select "header.bg-blue-900"
  end

  test "start action creates drill with filters" do
    post start_drills_path, params: { round: 1, clue_values: [ 200, 400 ] }

    drill_id = session[:current_drill_id]
    assert_not_nil drill_id, "Expected a drill to be created"

    drill = Drill.find(drill_id)
    assert_equal "1", drill.filters["round"]
    assert_equal [ 200, 400 ], drill.filters["clue_values"]
  end

  test "index displays correct coryat scores for drills" do
    drill = drills(:one)
    formatted_coryat = "$#{ActionController::Base.helpers.number_with_delimiter(drill.coryat_score)}"
    get drills_path
    assert_response :success
    assert_select "tbody>tr:first-child td:last-child", text: formatted_coryat
  end
end
