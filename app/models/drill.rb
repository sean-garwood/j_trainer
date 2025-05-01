class Drill < ApplicationRecord
  belongs_to :user, required: true
  has_many :drill_clues, dependent: :destroy
  has_many :clues, through: :drill_clues

  before_save :set_clues_seen_count

  def set_clues_seen_count
    self.clues_seen_count ||=
      self.correct_count + self.incorrect_count + self.pass_count
  end

  def increment_correct_count
    self.correct_count += 1
  end

  def increment_incorrect_count
    self.incorrect_count += 1
  end

  def increment_pass_count
    self.pass_count += 1
  end
end
