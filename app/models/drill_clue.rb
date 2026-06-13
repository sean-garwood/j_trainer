class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue

  # TODO:
  #  delegate :correct_response, :normalized_clue_value, :result to: :clue
  #  see https://edgeapi.rubyonrails.org/classes/ActiveRecord/DelegatedType.html
  delegate :correct_response, to: :clue
  delegate :normalized_clue_value, to: :clue

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  before_save :judge_response

  after_commit :update_drill_counts

  private

    def judge_response
      judgment = ResponseJudge.call(
        user_response: response,
        correct_response: correct_response
      )
      self.result = judgment.verdict
      self.score = judgment.score
      self.reason = judgment.reason
    end

    def update_drill_counts
      drill.update_counts!
    end
end
