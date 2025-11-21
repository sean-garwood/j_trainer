class Drill < ApplicationRecord
  belongs_to :user, required: true
  has_many :drill_clues, dependent: :destroy
  has_many :clues, through: :drill_clues

  after_save :update_counts!

  # TODO: add columns to the drills table to persist these values
  # could also create a separate DrillStats model if needed

  def stats
    {
      correct: correct_count,
      incorrect: incorrect_count,
      pass: pass_count,
      seen: clues_seen_count,
      accuracy: accuracy,
      coryat_score: coryat_score,
      max_possible_score: max_possible_score
    }
  end

  def accuracy
    return "0%" if clues_seen_count.zero?

    "#{(correct_count.to_f / clues_seen_count * 100).round(2)}%"
  end

  def filtered_clues
    scope = Clue.where.not(round: 3) # Exclude Final Jeopardy

    # Apply round filter
    scope = scope.where(round: filters["round"]) if filters["round"].present?

    # Apply clue values filter (array of specific values)
    scope = scope.where(normalized_clue_value: filters["clue_values"]) if filters["clue_values"].present? && filters["clue_values"].is_a?(Array)

    # Apply date range filters
    scope = scope.where(air_date: filters["date_after"]..) if filters["date_after"].present?
    scope = scope.where(air_date: ..filters["date_before"]) if filters["date_before"].present?

    scope
  end

  def fetch_clue
    pool = unseen_clue_ids
    return nil if pool.empty?

    clue = Clue.find(pool.sample)
    logger.info "Fetched clue #{clue.id} from filtered pool of #{pool.size} clues."
    clue
  end

  def update_counts!
    counts = drill_clues.group(:result).count

    update_columns(
      clues_seen_count: counts.values.sum,
      correct_count: counts["correct"] || 0,
      incorrect_count: counts["incorrect"] || 0,
      pass_count: counts["pass"] || 0,
      updated_at: Time.current
    )
  end

  def coryat_score
    score = 0
    drill_clues.includes(:clue).find_each do |dc|
      score = score.send(
        dc.result == "correct" ? :+ : :-, dc.clue.normalized_clue_value)
    end
    score
  end

  def max_possible_score
    drill_clues.includes(:clue).sum(:clue_value)
  end

  private

    # OPTIMIZE: before hook to cache seen IDs?
    # then pop/unshift as drill progresses.
    def unseen_clue_ids
      seen_ids = drill_clues.pluck(:clue_id)
      filtered_clues.where.not(id: seen_ids).pluck(:id)
    end
end
