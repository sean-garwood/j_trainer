class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue

  # TODO:
  #  delegate :correct_response, :normalized_clue_value, :result to: :clue
  #  see https://edgeapi.rubyonrails.org/classes/ActiveRecord/DelegatedType.html
  delegate :correct_response, to: :clue
  delegate :normalized_clue_value, to: :clue

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  # result doubles as the coryat sign; FILTER (not SUM(bool)) keeps this portable to Postgres
  def self.stats
    result = arel_table[:result]
    value = Clue.arel_table[:normalized_clue_value]
    tally = ->(verdict) { Arel.star.count.filter(result.eq(results.fetch(verdict))) }
    total = ->(expr) { Arel::Nodes::NamedFunction.new("COALESCE", [ expr.sum, 0 ]) }

    joins(:clue).select(
      Arel.star.count.as("seen"),
      tally.call(:correct).as("correct"),
      tally.call(:incorrect).as("incorrect"),
      tally.call(:pass).as("passed"),
      total.call(result * value).as("coryat"),
      total.call(value).as("max_possible")
    )
  end

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
