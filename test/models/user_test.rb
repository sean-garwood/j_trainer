require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email address" do
    @user = User.new(email_address: "SHOUT@YOU ", password: "password")
    assert @user.valid?
    assert_equal "shout@you", @user.email_address
  end

  test "validates presence of email address" do
    @user = User.new(email_address: nil, password: "password")
    assert_not @user.valid?
    assert_includes @user.errors[:email_address], "can't be blank"
  end

  test "destroys dependent sessions" do
    @user = users(:one)
    Session.create!(user: @user)
    assert_difference("Session.count", -1) do
      @user.destroy
    end
  end
end
