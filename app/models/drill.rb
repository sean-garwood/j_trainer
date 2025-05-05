class Drill < ApplicationRecord
  belongs_to :user, required: true
  has_many :drill_clues, dependent: :destroy
  has_many :clues, through: :drill_clues

  after_save :update_counts!

  def accuracy
    return "0%" if clues_seen_count.zero?

    (correct_count.to_f / clues_seen_count * 100).round(2).to_s + "%"
  end

  private
    def update_counts!
      total = drill_clues.count
      correct = drill_clues.correct.count
      incorrect = drill_clues.incorrect.count
      passed = drill_clues.pass.count

      Rails.logger.info "
      Updating drill counts:
        total=#{total},
        correct=#{correct},
        incorrect=#{incorrect},
        pass=#{passed}
      "

      self.update_columns(
        clues_seen_count: total,
        correct_count: correct,
        incorrect_count: incorrect,
        pass_count: passed,
        updated_at: Time.current
      )
    end
end
