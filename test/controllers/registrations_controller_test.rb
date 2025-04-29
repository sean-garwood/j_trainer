require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sign_up_path
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post sign_up_path, params: {
        user: {
          email_address: "new_user@example.com", # Use a different email than fixtures
          password: "secret",
          password_confirmation: "secret"
        }
      }
    end

    # Assuming redirect after successful signup
    assert_redirected_to root_path
  end

  test "should not create user with duplicate email" do
    # Using email from fixture
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: {
          email_address: users(:one).email_address, # Use fixture email
          password: "secret",
          password_confirmation: "secret"
        }
      }
    end

    # Assuming render :new on validation failure
    assert_response :unprocessable_entity
  end
end
