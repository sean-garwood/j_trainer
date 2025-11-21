class Clue < ApplicationRecord
  MIN_NORMALIZED_CLUE_VALUE = 200
  MAX_NORMALIZED_CLUE_VALUE = 2000

  has_many :drill_clues
  has_many :drills, through: :drill_clues

  # The lack of validations is due to the fact that the data is write-once and
  # clean as hell.

  def times_seen
    drills.count
  end
end
