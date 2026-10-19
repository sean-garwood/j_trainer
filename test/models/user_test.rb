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

  test "lifetime_stats sums across the user's drills only" do
    user = users(:one)
    user.drills.destroy_all
    add_results(user.drills.create!, one: :correct, two: :incorrect)
    add_results(user.drills.create!, three: :correct, old: :pass)
    add_results(users(:two).drills.create!, one: :correct)

    stats = user.lifetime_stats
    assert_equal [ 4, 2, 1, 1 ], [ stats.seen, stats.correct, stats.incorrect, stats.passed ]
    assert_equal 200 - 400 + 400, stats.coryat
    assert_equal 1200, stats.max_possible
  end
end
