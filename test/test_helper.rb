ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # threshold: 2 ensures parallelization when suite has < 50 tests
    parallelize(workers: :number_of_processors, threshold: 2)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # stubs ResponseJudge to treat the response text as the verdict, so results can be set directly
    def add_results(drill, results)
      judge = ->(user_response:, **) { ResponseJudge::Result.new(user_response.to_sym, nil, :stubbed) }
      ResponseJudge.stub(:call, judge) do
        results.each { |clue, result| drill.drill_clues.create!(clue: clues(clue), response: result.to_s) }
      end
    end
  end
end
