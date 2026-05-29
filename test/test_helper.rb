ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # threshold: 2 ensures parallelization when suite has < 50 tests
    parallelize(workers: :number_of_processors, threshold: 2)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
