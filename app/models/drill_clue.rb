class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue

  # TODO:
  #  delegate :correct_response, :normalized_clue_value, :result to: :clue
  #  see https://edgeapi.rubyonrails.org/classes/ActiveRecord/DelegatedType.html
  delegate :correct_response, to: :clue
  delegate :normalized_clue_value, to: :clue

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  # result doubles as the coryat sign; COUNT FILTER (not SUM(bool)) keeps this portable to Postgres
  scope :stats, lambda {
    joins(:clue).select(
      "COUNT(*) AS seen",
      "COUNT(*) FILTER (WHERE drill_clues.result = 1) AS correct",
      "COUNT(*) FILTER (WHERE drill_clues.result = -1) AS incorrect",
      "COUNT(*) FILTER (WHERE drill_clues.result = 0) AS passed",
      "COALESCE(SUM(drill_clues.result * clues.normalized_clue_value), 0) AS coryat",
      "COALESCE(SUM(clues.normalized_clue_value), 0) AS max_possible"
    )
  }

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
      drill.update_counts! unless destroyed?
    end
end
