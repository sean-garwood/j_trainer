class Drill < ApplicationRecord
  belongs_to :user, required: true
  has_many :drill_clues, dependent: :destroy
  has_many :clues, through: :drill_clues

  after_save :update_counts!

  Stats = Data.define(:seen, :correct, :incorrect, :passed, :coryat, :max_possible) do
    def self.for(drill_clues)
      from_tallies(drill_clues.group(:result).count, value_sums(drill_clues.group(:result)))
    end

    # two queries for any number of drills; drills with no clues get all-zero stats
    def self.by_drill(drill_clues)
      counts = nest(drill_clues.group(:drill_id, :result).count)
      values = nest(value_sums(drill_clues.group(:drill_id, :result)))
      counts.to_h { |id, tally| [ id, from_tallies(tally, values[id]) ] }.tap { it.default = from_tallies({}, {}) }
    end

    # counts and values are keyed by result name; coryat is signed by result, so passes drop out
    def self.from_tallies(counts, values)
      new(
        seen: counts.values.sum,
        correct: counts.fetch("correct", 0),
        incorrect: counts.fetch("incorrect", 0),
        passed: counts.fetch("pass", 0),
        coryat: values.fetch("correct", 0) - values.fetch("incorrect", 0),
        max_possible: values.values.sum
      )
    end

    def self.value_sums(grouped) = grouped.joins(:clue).sum("clues.normalized_clue_value")

    # {[drill_id, result] => n} -> {drill_id => {result => n}}
    def self.nest(grouped)
      grouped.each_with_object(Hash.new { |h, id| h[id] = {} }) { |((id, result), n), nested| nested[id][result] = n }
    end

    def accuracy = seen.zero? ? 0.0 : (correct * 100.0 / seen).round(2)
  end

  def stats = Stats.for(drill_clues)

  # OPTIMIZE: preload/includes to load once
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

  # OPTIMIZE
  def fetch_clue
    # OPTIMIZE: Do this once at startup, del id from pool as drill progresses.
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

  private

    # OPTIMIZE: before hook to cache seen IDs?
    # then pop/unshift as drill progresses.
    def unseen_clue_ids
      seen_ids = drill_clues.pluck(:clue_id)
      filtered_clues.where.not(id: seen_ids).pluck(:id)
    end
end
