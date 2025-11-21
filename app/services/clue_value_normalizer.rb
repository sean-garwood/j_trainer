module ClueValueNormalizer
  def self.normalize_clue_value(clue_value, air_date = clue_value.air_date)
    clue_value *= 2 if air_date_before_clue_value_change?(air_date) && clue_value.present?
    clue_value
  end

  def self.air_date_before_clue_value_change?(air_date)
    air_date.present? && air_date < "2001-11-26"
  end
end
