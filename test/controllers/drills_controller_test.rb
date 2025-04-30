require "test_helper"

class DrillsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get drills_index_url
    assert_response :success
  end

  test "should get new" do
    get drills_new_url
    assert_response :success
  end

  test "should get create" do
    get drills_create_url
    assert_response :success
  end

  test "should get show" do
    get drills_show_url
    assert_response :success
  end

  test "should get update" do
    get drills_update_url
    assert_response :success
  end
end
