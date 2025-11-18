class Drill < ApplicationRecord
  belongs_to :user, required: true
  has_many :drill_clues, dependent: :destroy
  has_many :clues, through: :drill_clues

  after_save :update_counts!

  def stats
    {
      correct: correct_count,
      incorrect: incorrect_count,
      pass: pass_count,
      seen: clues_seen_count,
      # TODO: add columns to the drills table to persist these values
      accuracy: accuracy,
      coryat_score: coryat_score,
      max_possible_score: max_possible_score
    }
  end

  def accuracy
    return "0%" if clues_seen_count.zero?

    (correct_count.to_f / clues_seen_count * 100).round(2).to_s + "%"
  end

  def fetch_clue
    pool = unseen_clue_ids
    return nil if pool.empty?

    clue = Clue.find(pool.sample)
    logger.info "Fetched clue #{clue.id} from pool of #{pool.size} clues."
    clue
  end

  def update_counts!
    total = drill_clues.count
    correct = drill_clues.correct.count
    incorrect = drill_clues.incorrect.count
    passed = drill_clues.pass.count

    update_columns(
      clues_seen_count: total,
      correct_count: correct,
      incorrect_count: incorrect,
      pass_count: passed,
      updated_at: Time.current
    )
  end

  def coryat_score
    score = 0
    drill_clues.includes(:clue).find_each do |dc|
      case dc.result
      when "correct"
        score += dc.clue.clue_value
      when "incorrect"
        score -= dc.clue.clue_value
      end
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
      Clue.where.not(id: seen_ids, round: 3)
        .pluck(:id) # exclude Final Jeopardy clues
    end
end
