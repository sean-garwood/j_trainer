class Drill < ApplicationRecord
  belongs_to :user, required: true
  before_save :clues_seen_count

  def clues_seen_count
    @clues_seen_count ||= 0
    self.correct_count + self.incorrect_count + self.pass_count
  end
end
