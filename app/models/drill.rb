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
      accuracy: accuracy
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

  private

    # TODO: session storage/cookie
    def unseen_clue_ids
      clues = Clue.where.not(id: drill_clues.select(:clue_id)).pluck(:id)
      logger.info "Unseen clues: #{clues.join(", ")}"

      clues
    end
end
