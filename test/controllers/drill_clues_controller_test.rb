require "test_helper"

class DrillCluesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @drill = drills(:one)
    @clue = clues(:one)
    sign_in @user
  end

  test "should create drill_clue with correct answer" do
    assert_difference("DrillClue.count", 1) do
      post drill_drill_clues_path(@drill), params: {
        drill_clue: {
          clue_id: @clue.id,
          response: @clue.correct_response,
          response_time: 3.5
        }
      }, as: :turbo_stream
    end

    drill_clue = DrillClue.last
    assert drill_clue.correct?, "Should be marked as correct"
    assert_equal 3.5, drill_clue.response_time
  end

  test "should create drill_clue with incorrect answer" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: "wrong answer",
        response_time: 2.0
      }
    }, as: :turbo_stream

    drill_clue = DrillClue.last
    assert drill_clue.incorrect?, "Should be marked as incorrect"
  end

  test "should create drill_clue with pass" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: "pass",
        response_time: 0
      }
    }, as: :turbo_stream

    drill_clue = DrillClue.last
    assert drill_clue.passed?, "Should be marked as pass"
  end

  test "should return turbo_stream response" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: @clue.correct_response,
        response_time: 1.0
      }
    }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should update drill counts after submission" do
    # Create a fresh drill without any existing drill_clues
    fresh_drill = Drill.create!(user: @user)
    initial_seen_count = fresh_drill.clues_seen_count
    initial_correct_count = fresh_drill.correct_count

    post drill_drill_clues_path(fresh_drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: @clue.correct_response,
        response_time: 1.5
      }
    }, as: :turbo_stream

    fresh_drill.reload
    assert_equal initial_seen_count + 1, fresh_drill.clues_seen_count, "Drill clues_seen_count should increment"
    assert_equal initial_correct_count + 1, fresh_drill.correct_count, "Drill correct_count should increment"
  end

  test "should fetch next clue after submission" do
    post drill_drill_clues_path(@drill), params: {
      drill_clue: {
        clue_id: @clue.id,
        response: "test",
        response_time: 1.0
      }
    }, as: :turbo_stream

    assert_response :success
    # Response should contain the next clue form
    assert_match /drill_clue_frame/, response.body
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
