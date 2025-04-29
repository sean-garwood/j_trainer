class Clue < ApplicationRecord
  MIN_NORMALIZED_CLUE_VALUE = 200
  MAX_NORMALIZED_CLUE_VALUE = 2000

  validates :clue_value,
    presence: true,
    inclusion: { in:
      MIN_NORMALIZED_CLUE_VALUE..MAX_NORMALIZED_CLUE_VALUE }
  validates :round,
    presence: true,
    inclusion: { in: 1..3 }
  validates :category, :question, :answer, :air_date, presence: true

  before_validation :normalize_clue_value

  private

    def validate_clue_value
      normalized = normalized_clue_value
      normalized >= MIN_NORMALIZED_CLUE_VALUE &&
        normalized <= MAX_NORMALIZED_CLUE_VALUE
    end

    def normalize_clue_value
      if air_date.present? && air_date < "2001-11-26" && clue_value.present?
        self.clue_value *= 2
      end
      clue_value
    end
end
