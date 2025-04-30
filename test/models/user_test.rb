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

  test "validates presence of password" do
    @user = User.new(email_address: "foo@bar", password: "")
    assert_not @user.valid?
  end
end
